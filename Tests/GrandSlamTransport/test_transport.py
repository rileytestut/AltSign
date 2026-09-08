#!/usr/bin/env python3
"""Exercise the production GSA transport against local, credential-free fixtures.

Requires macOS, Python 3, and Xcode command-line tools. No Apple service is called.
"""
from pathlib import Path
import argparse
import http.server
import threading
import plistlib
import subprocess
import json
import time
import tempfile

if not __debug__:
    raise RuntimeError('Run this regression test without Python optimization (-O).')

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--results', type=Path, help='Optional JSON result file')
args = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
rel = 'AltSign/Sources/ALTAppleAPI+Authentication.swift'
workspace = tempfile.TemporaryDirectory(prefix='altsign-gsa-test-')
base = Path(workspace.name)
records = []
lock = threading.Lock()
counts = {}
connections = 0


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'

    def setup(self):
        global connections
        super().setup()
        with lock:
            connections += 1
            self.number = connections

    def log_message(self, *args):
        pass

    def do_POST(self):
        request = plistlib.loads(self.rfile.read(int(self.headers['Content-Length'])))
        case = request['Request']['case']
        with lock:
            counts[case] = counts.get(case, 0) + 1
            n = counts[case]
            records.append({'case': case, 'attempt': n, 'connection': self.number, 'time': time.monotonic(), 'ua': self.headers.get('User-Agent')})
        status = 200
        payload = {'Response': {'Status': {'ec': 0}}}
        body = None
        if case == 'recover' and n == 1:
            status = 503
            body = b'<html>PRIVATE_MARKER</html>'
        elif case == 'persistent':
            status = 503
            body = b'<html>PRIVATE_MARKER</html>'
        elif case == 'structured503':
            status = 503
            payload = {'Response': {'Status': {'ec': -20101, 'em': 'Incorrect fixture credentials'}}}
        elif case == 'challenge409':
            status = 409
            payload = {'Response': {'Status': {'ec': 0, 'au': 'trustedDeviceSecondaryAuth'}}}
        elif case == 'success503':
            status = 503
        elif case == 'missingCode409':
            status = 409
            payload = {'Response': {'Status': {'au': 'secondaryAuth'}}}
        elif case == 'structured200':
            payload = {'Response': {'Status': {'ec': -22406, 'em': 'Incorrect fixture credentials'}}}
        elif case == 'anisette503':
            status = 503
            payload = {'Response': {'Status': {'ec': -22421, 'em': 'Invalid fixture anisette'}}}
        elif case == 'apple503':
            status = 503
            payload = {'Response': {'Status': {'ec': -12345, 'em': 'Fixture Apple error'}}}
        elif case == 'html200':
            body = b'<html>PRIVATE_MARKER</html>'
        elif case == 'html401':
            status = 401
            body = b'<html>PRIVATE_MARKER</html>'
        elif case == 'array200':
            payload = ['PRIVATE_MARKER']
        elif case == 'timeout':
            time.sleep(1)
        elif case == 'shortBudget':
            status = 503
            body = b'<html>PRIVATE_MARKER</html>'
        if body is None:
            body = plistlib.dumps(payload)
            ct = 'text/x-xml-plist'
        else:
            ct = 'text/html'
        try:
            self.send_response(status)
            self.send_header('Content-Type', ct)
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            pass

server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)

threading.Thread(target=server.serve_forever, daemon=True).start()

header='''import Foundation
struct ALTAnisetteData { let deviceDescription: String }
let ALTUnderlyingAppleAPIErrorDomain = "Fixture.AppleAPI"
struct ALTAppleAPIError: Error {
    enum Code: Int { case incorrectCredentials = 1, invalidAnisetteData = 2 }
    let code: Code
    init(_ code: Code) { self.code = code }
    static func unknown() -> Error { NSError(domain: "Fixture", code: -1) }
}
final class FailingProtocol: URLProtocol {
    static var calls = 0
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "fixture.invalid" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.calls += 1
        let response = HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        let code: URLError.Code = request.url!.path == "/cancel" ? .cancelled : .notConnectedToInternet
        client?.urlProtocol(self, didFailWithError: URLError(code))
    }
    override func stopLoading() {}
}
// Inject only the offline/cancellation fixture protocol into otherwise normal ephemeral sessions.
enum URLSessionConfiguration {
    static var ephemeral: Foundation.URLSessionConfiguration {
        let configuration = Foundation.URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FailingProtocol.self] + (configuration.protocolClasses ?? [])
        return configuration
    }
}
class ALTAppleAPI {
'''

footer='''}
_ = URLProtocol.registerClass(FailingProtocol.self)
let api = ALTAppleAPI()
let port = CommandLine.arguments[1]
let cases = ["recover", "persistent", "challenge409", "success503", "missingCode409", "structured503", "structured200", "anisette503", "apple503", "html200", "html401", "array200", "cancel", "network", "timeout", "shortBudget", "expired"]
var reports = [[String: Any]]()
for name in cases {
    let signal = DispatchSemaphore(value: 0)
    let lock = NSLock()
    var completions = 0
    var report: [String: Any] = ["case": name]
    let start = ProcessInfo.processInfo.systemUptime
    let callback: (Result<[String: Any], Error>) -> Void = { result in
        lock.lock()
        completions += 1
        switch result {
        case .success: report["result"] = "success"
        case .failure(let error):
            if let apple = error as? ALTAppleAPIError {
                report["result"] = "error"; report["domain"] = "Fixture.TypedAppleAPI"; report["code"] = apple.code.rawValue
            } else {
                let ns = error as NSError
                report["result"] = "error"; report["domain"] = ns.domain; report["code"] = ns.code; report["message"] = ns.localizedDescription
                report["hasUnderlyingError"] = ns.userInfo[NSUnderlyingErrorKey] != nil
                assert(!String(describing: ns.userInfo).contains("PRIVATE_MARKER"), "response body leaked")
            }
        }
        lock.unlock()
        signal.signal()
    }
    if ["cancel", "network", "timeout", "shortBudget", "expired"].contains(name) {
        let url = ["cancel", "network"].contains(name) ? URL(string: "http://fixture.invalid/\\(name)")! : URL(string: "http://127.0.0.1:\\(port)/GsService2")!
        var request = URLRequest(url: url); request.httpMethod = "POST"
        request.httpBody = try! PropertyListSerialization.data(fromPropertyList: ["Request": ["case": name]], format: .xml, options: 0)
        let budget: TimeInterval = name == "expired" ? -1 : (name == "timeout" || name == "shortBudget" ? 0.5 : 20)
        api.sendGrandSlamRequest(request, attempt: 1, deadline: start + budget, completionHandler: callback)
    } else {
        api.sendAuthenticationRequest(parameters: ["case": name], anisetteData: ALTAnisetteData(deviceDescription: "fixture"), completionHandler: callback)
    }
    assert(signal.wait(timeout: .now() + 23) == .success, "deadline/completion failure")
    Thread.sleep(forTimeInterval: 0.05)
    lock.lock(); report["completions"] = completions; report["elapsed"] = ProcessInfo.processInfo.systemUptime - start; lock.unlock()
    assert(completions == 1)
    reports.append(report)
}
assert(FailingProtocol.calls == 2, "transport fixture count: \\(FailingProtocol.calls)")
let encoded = try! JSONSerialization.data(withJSONObject: reports, options: [.sortedKeys])
print(String(data: encoded, encoding: .utf8)!)
'''

try:
    source = (repo / rel).read_text()
    start = source.index('    func sendAuthenticationRequest(')
    end = source.index('    func makeTwoFactorCodeRequest(', start)
    method = source[start:end]
    assert method.count('https://gsa.apple.com/grandslam/GsService2') == 1
    method = method.replace('https://gsa.apple.com/grandslam/GsService2', f'http://127.0.0.1:{server.server_port}/GsService2')
    path = base / 'retries.swift'
    path.write_text(header + method + footer)
    compile = subprocess.run(['xcrun', 'swiftc', '-swift-version', '5', '-module-cache-path', str(base / 'module-cache'), str(path), '-o', str(base / 'retries')], capture_output=True, text=True)
    if compile.returncode:
        raise RuntimeError(compile.stderr)
    print('COMPILE PASS: production methods with only the destination replaced by a local fixture.', flush=True)
    if compile.stderr:
        print(compile.stderr, flush=True)
    run = subprocess.run([str(base / 'retries'), str(server.server_port)], capture_output=True, text=True, timeout=45)
    if run.returncode:
        raise RuntimeError(run.stderr + run.stdout)
    results = json.loads(run.stdout)
    by = {r['case']: r for r in results}
    for r in results:
        assert r['completions'] == 1
    assert by['recover']['result'] == 'success' and counts['recover'] == 2
    for name in ['challenge409', 'success503', 'missingCode409']:
        assert by[name]['result'] == 'success' and counts[name] == 1
    assert by['persistent']['code'] == -1011 and counts['persistent'] == 5 and (15 <= by['persistent']['elapsed'] < 20)
    p = [r for r in records if r['case'] == 'persistent']
    gaps = [p[i + 1]['time'] - p[i]['time'] for i in range(4)]
    for (expected, actual) in zip([1, 2, 4, 8], gaps):
        assert expected <= actual < expected + 1, (expected, actual)
    assert len({r['connection'] for r in records}) == len(records), 'session connection reused'
    for (name, code) in [('structured503', 1), ('structured200', 1), ('anisette503', 2)]:
        assert by[name]['domain'] == 'Fixture.TypedAppleAPI' and by[name]['code'] == code and (counts[name] == 1)
    assert by['apple503']['domain'] == 'Fixture.AppleAPI' and by['apple503']['code'] == -12345 and (by['apple503']['message'] == 'Fixture Apple error (-12345)') and (counts['apple503'] == 1)
    for name in ['html200', 'html401', 'array200']:
        assert by[name]['code'] == -1011 and counts[name] == 1 and (not by[name]['hasUnderlyingError'])
    for (name, code) in [('cancel', -999), ('network', -1009)]:
        assert by[name]['domain'] == 'NSURLErrorDomain' and by[name]['code'] == code
    assert by['timeout']['code'] == -1001 and counts['timeout'] == 1 and (by['timeout']['elapsed'] < 1)
    assert by['shortBudget']['code'] == -1011 and counts['shortBudget'] == 1 and (by['shortBudget']['elapsed'] < 1)
    assert by['expired']['code'] == -1001 and counts.get('expired', 0) == 0
    modern = 'AuthKit/1 (Macintosh; OS X 26.5.2) (com.apple.dt.Xcode/26.0)'
    assert all((r['ua'] == modern for r in records if r['case'] not in ['timeout', 'shortBudget']))
    output = {'cases': results, 'requests': records, 'persistentRetryGaps': gaps}
    if args.results:
        args.results.write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps(results, indent=2))
    print('PASS: 17 production-method scenarios; fresh connections, exact backoff, five attempts, deadline/timeouts, structured Apple errors, cancellation/network passthrough, malformed-body redaction, completion once.')
finally:
    server.shutdown()
    server.server_close()
    workspace.cleanup()
