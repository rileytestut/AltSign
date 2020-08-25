//
//  GSAContext.swift
//  AltSign
//
//  Created by Riley Testut on 8/15/20.
//  Copyright © 2020 Riley Testut. All rights reserved.
//

import Foundation
import CoreCrypto

class GSAContext
{
    let username: String
    let password: String
    
    /// salt (obtained from server)
    var salt: Data?
    
    /// B (Public)
    var serverPublicKey: Data?
    
    /// K
    var sessionKey: Data?
    
    var dsid: String?
    
    /// A (Public)
    private(set) var publicKey: Data?
        
    /// x (derived with KDF)
    private(set) var derivedPasswordKey: Data?
    
    /// M1
    private(set) var verificationMessage: Data?
    
    /// SRP group: https://tools.ietf.org/html/rfc5054#page-16
    private let srpGroup = ccsrp_gp_rfc5054_2048()!
    
    private let digestInfo = ccsha256_di()!
    
    private lazy var srpContext: ccsrp_ctx_t = {
        let size = ccsrp_sizeof_srp(self.digestInfo, self.srpGroup)
        let context = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment).assumingMemoryBound(to: ccsrp_ctx.self)
        ccsrp_ctx_init(context, self.digestInfo, self.srpGroup)
        ccsrp_client_set_noUsernameInX(context, true)
        context.pointee.blinding_rng = ccrng(nil)
        return context
    }()
    
    init(username: String, password: String)
    {
        self.username = username
        self.password = password
    }
    
    deinit
    {
        self.srpContext.deallocate()
    }
}

extension GSAContext
{
    func start() -> Data?
    {
        guard self.publicKey == nil else { return nil }
        
        self.publicKey = self.makeAKey()
        return self.publicKey
    }
    
    func makeVerificationMessage(iterations: Int, isHexadecimal: Bool) -> Data?
    {
        guard self.verificationMessage == nil else { return nil }
        guard let salt = self.salt, let serverPublicKey = self.serverPublicKey else { return nil }
        
        guard let derivedPasswordKey = self.makeX(password: self.password, salt: salt, iterations: iterations, isHexadecimal: isHexadecimal) else { return nil }
        self.derivedPasswordKey = derivedPasswordKey
        
        self.verificationMessage = self.makeM1(username: self.username, derivedPasswordKey: derivedPasswordKey, salt: salt, serverPublicKey: serverPublicKey)
        return self.verificationMessage
    }
    
    func verifyServerVerificationMessage(_ serverVerificationMessage: Data) -> Bool
    {
        guard !serverVerificationMessage.isEmpty else { return false }
        
        let isValid = serverVerificationMessage.withUnsafeBytes { (bytes) -> Bool in
            let pointer = bytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
            return ccsrp_client_verify_session(self.srpContext, pointer)
        }
        
        return isValid
    }
    
    func makeChecksum(appName: String) -> Data?
    {
        guard let sessionKey = self.sessionKey, let dsid = self.dsid else { return nil }
        
        let size = cchmac_di_size(self.digestInfo)
        
        let context = Data.makeBuffer(size: size, type: cchmac_ctx.self)
        defer { context.deallocate() }
        
        sessionKey.withUnsafeBytes { cchmac_init(self.digestInfo, context, sessionKey.count, $0.baseAddress) }
        
        for string in ["apptokens", dsid, appName]
        {
            cchmac_update(self.digestInfo, context, string.count, string)
        }
        
        var checksum = Data(repeating: 0, count: self.digestInfo.pointee.output_size)
        checksum.withUnsafeMutableBytes { cchmac_final(self.digestInfo, context, $0.baseAddress?.assumingMemoryBound(to: UInt8.self)) }
        return checksum
    }
}

internal extension GSAContext
{
    func makeHMACKey(_ string: String) -> Data
    {
        var keySize = 0
        let rawSessionKey = ccsrp_get_session_key(self.srpContext, &keySize)
        
        var sessionKey = Data(repeating: 0, count: keySize)
        sessionKey.withUnsafeMutableBytes { cchmac(self.digestInfo, keySize, rawSessionKey, string.count, string, $0.baseAddress?.assumingMemoryBound(to: UInt8.self)) }
        return sessionKey
    }
}

private extension GSAContext
{
    func makeAKey() -> Data?
    {
        let size = ccsrp_exchange_size(self.srpContext)
        
        var keyA = Data(repeating: 0, count: size)
        let result = keyA.withUnsafeMutableBytes { ccsrp_client_start_authentication(self.srpContext, ccrng(nil), $0.baseAddress!) }
        
        guard result == 0 else { return nil }
        return keyA
    }
    
    func makeX(password: String, salt: Data, iterations: Int, isHexadecimal: Bool) -> Data?
    {
        var digest = Data(repeating: 0, count: self.digestInfo.pointee.output_size)
        digest.withUnsafeMutableBytes { ccdigest(self.digestInfo, password.utf8.count, password, $0.baseAddress!) }
        
        let digestLength = isHexadecimal ? self.digestInfo.pointee.output_size * 2 : self.digestInfo.pointee.output_size
        
        if isHexadecimal
        {
            let hexDigest = digest.hexadecimal()
            digest = hexDigest
        }
        
        var x = Data(repeating: 0, count: self.digestInfo.pointee.output_size)
        
        let result = x.withUnsafeMutableBytes { (xBytes) in
            digest.withUnsafeBytes { (digestBytes) in
                salt.withUnsafeBytes { (saltBytes) in
                    ccpbkdf2_hmac(self.digestInfo, digestLength, digestBytes.baseAddress, salt.count, saltBytes.baseAddress, iterations, self.digestInfo.pointee.output_size, xBytes.baseAddress)
                }
            }
        }
        
        guard result == 0 else { return nil }
        return x
    }
    
    func makeM1(username: String, derivedPasswordKey x: Data, salt: Data, serverPublicKey B: Data) -> Data?
    {
        let size = ccsrp_get_session_key_length(self.srpContext)
        
        var M1 = Data(repeating: 0, count: size)
        
        let result = M1.withUnsafeMutableBytes { (m1Bytes) in
            x.withUnsafeBytes { (xBytes) in
                salt.withUnsafeBytes { (saltBytes) in
                    B.withUnsafeBytes { (bBytes) in
                        ccsrp_client_process_challenge(self.srpContext, username, xBytes.count, xBytes.baseAddress!,
                                                       salt.count, saltBytes.baseAddress!, bBytes.baseAddress!, m1Bytes.baseAddress!)
                    }
                }
            }
        }

        guard result == 0 else { return nil }
        return M1
    }
}
