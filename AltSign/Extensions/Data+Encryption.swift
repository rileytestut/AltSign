//
//  Data+Encryption.swift
//  AltSign
//
//  Created by Riley Testut on 8/20/20.
//  Copyright © 2020 Riley Testut. All rights reserved.
//

import Foundation
import CoreCrypto

extension Data
{
    static func makeBuffer<T>(size: Int, type: T.Type) -> UnsafeMutablePointer<T>
    {
        return UnsafeMutableRawPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment).assumingMemoryBound(to: type)
    }
    
    func hexadecimal() -> Data
    {
        let hexString = self.map { String(format: "%02hhx", $0) }.joined()
        
        let hexData = Data(hexString.flatMap { $0.utf8.map { UInt8($0) } })
        return hexData
    }
    
    func decryptedCBC(context gsaContext: GSAContext) -> Data?
    {
        guard let mode = ccaes_cbc_decrypt_mode() else { return nil }
        
        let context = Data.makeBuffer(size: mode.pointee.size, type: cccbc_ctx.self)
        defer { context.deallocate() }
                
        let sessionKey = gsaContext.makeHMACKey("extra data key:")
        _ = sessionKey.withUnsafeBytes { mode.pointee.`init`(mode, context, sessionKey.count, $0.baseAddress) }
        
        var initializationVector = gsaContext.makeHMACKey("extra data iv:")
        var decryptedData = Data(repeating: 0, count: self.count)
        
        let size = decryptedData.withUnsafeMutableBytes { (decryptedBytes) in
            self.withUnsafeBytes { (dataBytes) in
                initializationVector.withUnsafeMutableBytes { (ivBytes) -> size_t in
                    let ivPointer = ivBytes.baseAddress!.assumingMemoryBound(to: cccbc_iv.self)
                    return ccpad_pkcs7_decrypt(mode, context, ivPointer, self.count, dataBytes.baseAddress, decryptedBytes.baseAddress)
                }
            }
        }
        
        guard size <= self.count else { return nil }
        return decryptedData
    }
    
    func decryptedGCM(context gsaContext: GSAContext) -> Data?
    {
        guard let mode = ccaes_gcm_decrypt_mode(),
              let sessionKey = gsaContext.sessionKey else { return nil }
        
        let context = Data.makeBuffer(size: mode.pointee.size, type: ccgcm_ctx.self)
        defer { context.deallocate() }
        
        _ = sessionKey.withUnsafeBytes { mode.pointee.`init`(mode, context, sessionKey.count, $0.baseAddress!) }
        
        let versionSize = 3
        let ivSize = 16
        let tagSize = 16
        
        let decryptedSize = self.count - (versionSize + ivSize + tagSize)
        guard decryptedSize > 0 else { return nil }
        
        let version = self[0 ..< versionSize]
        let initializationVector = self[versionSize ..< versionSize + ivSize]
        let ciphertext = self.dropFirst(versionSize + ivSize).dropLast(tagSize)
        let tag = self[self.endIndex - tagSize ..< self.endIndex]
        
        _ = initializationVector.withUnsafeBytes { mode.pointee.set_iv(context, ivSize, $0.baseAddress) }
        _ = version.withUnsafeBytes { mode.pointee.gmac(context, version.count, $0.baseAddress) }
        
        var decryptedData = Data(repeating: 0, count: decryptedSize)
        _ = ciphertext.withUnsafeBytes { (ciphertextBytes) in
            decryptedData.withUnsafeMutableBytes { (decryptedBytes) in
                mode.pointee.gcm(context, decryptedSize, ciphertextBytes.baseAddress, decryptedBytes.baseAddress)
            }
        }
        
        var decryptedTag = Data(repeating: 0, count: tagSize)
        _ = decryptedTag.withUnsafeMutableBytes { mode.pointee.finalize(context, tagSize, $0.baseAddress) }
        
        guard tag == decryptedTag else { return nil }
        return decryptedData
    }
}
