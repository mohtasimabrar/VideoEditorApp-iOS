//
//  ViewController.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 9/11/23.
//

import UIKit

class ViewController: UIViewController, UINavigationControllerDelegate {
    
    private lazy var selectMediaButton: UIButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setTitle("Select Video", for: .normal)
        $0.backgroundColor = .blue
        $0.addTarget(self, action: #selector(selectMediaButtonTapped), for: .touchUpInside)
        
        return $0
    }(UIButton())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        
    }
    
    private func setupView() {
        view.addSubview(selectMediaButton)
        
        NSLayoutConstraint.activate([
            selectMediaButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectMediaButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc func selectMediaButtonTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.movie"]
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            let editorVC = EditorViewController()
            editorVC.videoURL = videoURL
            
            self.navigationController?.pushViewController(editorVC, animated: true)
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}