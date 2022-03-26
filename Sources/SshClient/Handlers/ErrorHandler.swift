import NIO
import NIOSSH

final class ErrorHandler: ChannelInboundHandler {
    typealias InboundIn = Any

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: Error in pipeline: \(error)", to: &StdErr.stream)
        context.close(promise: nil)
    }
}
