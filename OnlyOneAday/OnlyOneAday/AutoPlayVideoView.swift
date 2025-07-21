import SwiftUI
import AVFoundation

class PlayerContainerView: UIView {
    let playerLayer = AVPlayerLayer()
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct AutoPlayVideoView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        let player = AVPlayer(url: url)
        player.isMuted = false
        player.actionAtItemEnd = .none

        view.player = player
        view.playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(view.playerLayer)

        // ループ再生
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }

        player.play()
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        // layoutSubviewsで自動調整されるので何もしなくてOK
    }

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: ()) {
        uiView.player?.pause()
        uiView.player = nil
    }
} 