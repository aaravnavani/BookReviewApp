//
//  ViewController.swift
//  BookReviewApp
//
//  Created by Aarav Navani on 6/27/20.
//  Copyright © 2020 ESUHSD. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision
import VisionKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    private var scanButton = ScanButton(frame: .zero)
    private var scanImageView = ScanImageView(frame: .zero)
    private var ocrTextView = OcrTextView(frame: .zero, textContainer: nil)
    private var ocrRequest = VNRecognizeTextRequest(completionHandler: nil)
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        configure()
        configureOCR()
        
        let text = SCNText(string: ocrTextView, extrusionDepth: 2)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.magenta
        text.materials = [material]
        
        let node = SCNNode()
        node.position = SCNVector3(x:0, y:0.02, z:-0.1)
        node.scale = SCNVector3(x:0.01, y:0.01, z:0.01)
        node.geometry = text
        
        sceneView.scene.rootNode.addChildNode(node)
        sceneView.autoenablesDefaultLighting = true
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    private func configure() {
            view.addSubview(scanImageView)
            view.addSubview(ocrTextView)
            view.addSubview(scanButton)
            
            let padding: CGFloat = 16
            NSLayoutConstraint.activate([
                scanButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
                scanButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
                scanButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding),
                scanButton.heightAnchor.constraint(equalToConstant: 50),
                
                ocrTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
                ocrTextView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
                ocrTextView.bottomAnchor.constraint(equalTo: scanButton.topAnchor, constant: -padding),
                ocrTextView.heightAnchor.constraint(equalToConstant: 200),
                
                scanImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
                scanImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
                scanImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
                scanImageView.bottomAnchor.constraint(equalTo: ocrTextView.topAnchor, constant: -padding)
            ])
            
            scanButton.addTarget(self, action: #selector(scanDocument), for: .touchUpInside)
        }
        
        
        @objc private func scanDocument() {
            let scanVC = VNDocumentCameraViewController()
            scanVC.delegate = self
            present(scanVC, animated: true)
        }
        
        
        private func processImage(_ image: UIImage) {
            guard let cgImage = image.cgImage else { return }

            ocrTextView.text = ""
            scanButton.isEnabled = false
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([self.ocrRequest])
            } catch {
                print(error)
            }
        }

        
        private func configureOCR() {
            ocrRequest = VNRecognizeTextRequest { (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
                var ocrText = ""
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { return }
                    
                    ocrText += topCandidate.string + "\n"
                }
                
                
                
                var html = ""
                let scheme = "https"
                let host = "www.amazon.com"
                let path = "/s"
                let k =  ocrText
                let i = "stripbooks"
                let kItem = URLQueryItem(name: "k", value: k)
                let iItem = URLQueryItem(name: "i", value: i)
                
                var urlComponents = URLComponents()
                urlComponents.scheme = scheme
                urlComponents.host = host
                urlComponents.path = path
                urlComponents.queryItems = [kItem, iItem]
                
                guard let url = urlComponents.url else { return }
                
               
                
                print(url)
                
                
                
                //URL(string: "https://www.amazon.com" + "/s?k=" + text   + "&i=stripbooks")!
                URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let data = data else {
                        print(error ?? "")
                        return
                    }
                    html = String(data: data, encoding: .utf8)!
                    let pattern = #"(\d.\d) out of 5 stars"#
                    if let range = html.range(of: pattern, options: .regularExpression) {
                        let rating = html[range].prefix(3)
                        ocrText = ""
                        ocrText = ocrText + rating
                        DispatchQueue.main.async {
                            self.ocrTextView.text = ocrText
                            self.scanButton.isEnabled = true
                        }
                        
                    }
                    
                }.resume()
                
            }
            
            ocrRequest.recognitionLevel = .accurate
            ocrRequest.recognitionLanguages = ["en-US", "en-GB "]
            ocrRequest.usesLanguageCorrection = true
        }
    }


    extension ViewController: VNDocumentCameraViewControllerDelegate {
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount >= 1 else {
                controller.dismiss(animated: true)
                return
            }
            
            scanImageView.image = scan.imageOfPage(at: 0)
            processImage(scan.imageOfPage(at: 0))
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            //Handle properly error
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
    
    
}
