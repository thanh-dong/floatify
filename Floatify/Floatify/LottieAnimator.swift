import SwiftUI
import Lottie

// MARK: - DismissController

class DismissController: ObservableObject {
    @Published var shouldDismiss = false
    var onDismissComplete: (() -> Void)?

    func dismiss(completion: @escaping () -> Void) {
        onDismissComplete = completion
        shouldDismiss = true
    }
}

// MARK: - LottiePanelBackground

struct LottiePanelBackground: NSViewRepresentable {
    let animationName: String
    @Binding var isPlaying: Bool
    var onEntryComplete: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: animationName, bundle: .main)
        view.contentMode = .scaleAspectFill
        view.loopMode = .playOnce
        view.isHidden = true
        context.coordinator.animationView = view
        return view
    }

    func updateNSView(_ nsView: LottieAnimationView, context: Context) {
        if isPlaying && nsView.isHidden {
            nsView.isHidden = false
            nsView.play { finished in
                if finished {
                    DispatchQueue.main.async {
                        nsView.isHidden = true
                        self.isPlaying = false
                        self.onEntryComplete?()
                    }
                }
            }
        }
    }

    class Coordinator {
        var animationView: LottieAnimationView?
    }
}
