import Foundation

struct StdErr: TextOutputStream {
    mutating func write(_ string: String) { fputs(string, stderr) }
    static var stream = Self()
}
