/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A scene used to indicate the progress of loading additional content between scenes.
*/

import SpriteKit

class ProgressScene: BaseScene {
    
    
    // -----------------------------------------------------------------
    // MARK: - Properties
    // -----------------------------------------------------------------
    
    // Returns the background node from the scene.
    override var backgroundNode: SKSpriteNode? {
        return childNode(withName: .backgroundNode) as? SKSpriteNode
    }
    
    private var labelNode: SKLabelNode? {
   
        guard let label: SKLabelNode = backgroundNode!.childNode(withName: .label) as? SKLabelNode else {
            return nil
        }
        
        return label
    }
    
    private var progressBarNode: SKSpriteNode? {
        
        guard let progressBar: SKSpriteNode = backgroundNode!.childNode(withName: .progressBar) as? SKSpriteNode else {
            return nil
        }
        
        return progressBar
    }
    
    /*
        Because we're using a factory method for initialization (we want to load
        the scene from a file, but `init(fileNamed:)` is not a designated init),
        we need to make most of the properties `var` and implicitly unwrapped
        optional so we can set the properties after creating the scene with
        `progressScene(withSceneLoader sceneLoader:)`.
    */
    
    // The scene loader currently handling the requested scene.
    private var sceneLoader: SceneLoader!
    
    // Keeps track of the progress bar's initial width.
    private var progressBarInitialWidth: CGFloat!
    
    
    // -----------------------------------------------------------------
    // MARK: - Initializers
    // -----------------------------------------------------------------

    // Constructs a `ProgressScene` that will monitor the download progress of on demand resources and the loading progress of bringing assets into memory.
    static func progressScene(withSceneLoader loader: SceneLoader) -> ProgressScene? {
        
        // Load the progress scene from its sks file.
        guard let progressScene: ProgressScene = ProgressScene(asset: .progressScene) else {
            return nil
        }
        
        progressScene.createCamera()
        progressScene.setup(withSceneLoader: loader)
        
        // Return the setup progress scene.
        return progressScene
    }
    
    func setup(withSceneLoader loader: SceneLoader) {
        
        // Set the sceneLoader. This may be in the downloading or preparing state.
        self.sceneLoader = loader
        
        // Register for notifications posted when the `SceneDownloader` fails.
        NotificationCenter.default.addObserver(self, selector: #selector(downloadFailed(notification:)),
                                               name: .sceneLoaderDidFailNotification,
                                               object: sceneLoader)
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Scene Life Cycle
    // -----------------------------------------------------------------
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        guard let position: CGPoint = backgroundNode?.position as? CGPoint else {
            return
        }
        
        centerCameraOnPoint(point: position)

        // Remember the progress bar's initial width. It will change to indicate progress.
        progressBarInitialWidth = progressBarNode?.frame.width
        
        if let error: Error = sceneLoader.error {
            showError(.sceneLoader(error.localizedDescription))
        } else {
            showDefaultState()
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Notification handling
    // -----------------------------------------------------------------
    
    @objc func downloadFailed(notification: Notification) {
        
        DispatchQueue.main.async { [weak self] in
            
            guard let loader: SceneLoader = notification.object as? SceneLoader, let error: Error = loader.error else {
                fatalError("The scene loader has no error to show.")
            }
            
            self?.showError(.downloadFailed(error.localizedDescription))
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - ButtonNodeResponderType
    // -----------------------------------------------------------------

    override func buttonTriggered(button: ButtonNode) {
        
        guard let buttonIdentifier: ButtonIdentifier = button.buttonIdentifier else {
            return
        }
        
        switch buttonIdentifier {
            case .retry:
                self.sceneLoader.requestedForPresentation = true
                showDefaultState()
            case .cancel:
               print("Cancel")
            default:
                // Allow `BaseScene` to handle the event in `BaseScene+Buttons`.
                super.buttonTriggered(button: button)
        }
    }
    
    
    // -----------------------------------------------------------------
    // MARK: - Convenience
    // -----------------------------------------------------------------

    func button(withId identifier: ButtonIdentifier) -> ButtonNode? {
        return backgroundNode?.childNode(withName: identifier.identifer) as? ButtonNode
    }
    
    func showDefaultState() {
        progressBarNode?.isHidden = false
        
        // Only display the "Cancel" button.
        button(withId: .home)?.isHidden = true
        button(withId: .retry)?.isHidden = true
        button(withId: .cancel)?.isHidden = false
        
        // Reset the button focus.
        resetFocus()
    }
    
    func showError(_ error: GameErrors) {
        
        // Display "Quit" and "Retry" buttons.
        button(withId: .home)?.isHidden = false
        button(withId: .retry)?.isHidden = false
        button(withId: .cancel)?.isHidden = true
        
        // Hide normal state.
        progressBarNode?.isHidden = true
        progressBarNode?.size.width = 0.0
        
        // Reset the button focus.
        resetFocus()
        
        // Check if the error was due to the user cancelling the operation.
        switch error {
        case .downloadFailed(let value) where (value.contains(NSCocoaErrorDomain) && value.contains(NSCocoaErrorDomain)):
            labelNode?.text = NSLocalizedString("Cancelled", comment: "Displayed when the user cancels loading.")
        case .sceneLoader(let value) where (value.contains(NSCocoaErrorDomain) && value.contains(NSCocoaErrorDomain)):
            labelNode?.text = NSLocalizedString("Cancelled", comment: "Displayed when the user cancels loading.")
        default:
            showAlert(for: error)
        }
    }
    
    // -----------------------------------------------------------------
    // MARK: - Alert Handling
    // -----------------------------------------------------------------
    
    func showAlert(for error: Error) {
        self.labelNode?.text = NSLocalizedString("Failed", comment: "Displayed when the scene loader fails to load a scene.")
        
        // Display the error description in a native alert.
        #if os(OSX)
            guard let window: NSWindow = view?.window else {
                fatalError("Attempting to present an error when the scene is not in a window.")
            }
             
            let alert: NSAlert = NSAlert(error: error)
            alert.beginSheetModal(for: window, completionHandler: nil)
        #else
        
            guard let rootViewController: UIViewController = view?.window?.rootViewController else {
                fatalError("Attempting to present an error when the scene is not in a view controller.")
            }
            
            let alert: UIAlertController = UIAlertController(title: error.localizedDescription,
                                                             message: error.localizedDescription,
                                                             preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            rootViewController.present(alert, animated: true, completion: nil)
        #endif
    }
}
