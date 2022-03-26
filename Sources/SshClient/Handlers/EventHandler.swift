import NIO
import NIOSSH

final class EventHandler: ChannelInboundHandler {
    typealias InboundIn = Any

    var authenticationResultPromise: EventLoopPromise<Void>?
    var authenticated: Bool = false

    func requestAuthenticationResult(_ promise: EventLoopPromise<Void>) {
        if self.authenticated {
            promise.succeed(())
        } else {
            self.authenticationResultPromise = promise
        }
    }

    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        if event is UserAuthSuccessEvent {
            authenticated = true
            if let authenticationResultPromise = self.authenticationResultPromise {
                self.authenticationResultPromise = nil
                authenticationResultPromise.succeed(())
            }
        }
    }

    func handlerRemoved(context: ChannelHandlerContext) {
        if let authenticationResultPromise = self.authenticationResultPromise {
            self.authenticationResultPromise = nil
            authenticationResultPromise.fail(SshClientError.authenticatedStateNotReached)
        }
    }
}
