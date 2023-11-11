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
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .systemPink
        $0.titleEdgeInsets = UIEdgeInsets(top: 10,left: 10,bottom: 10,right: 10)
        $0.layer.cornerRadius = 10.0
        $0.addTarget(self, action: #selector(selectMediaButtonTapped), for: .touchUpInside)
        
        return $0
    }(UIButton())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Video Editor"
        view.backgroundColor = .white
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func setupView() {
        view.addSubview(selectMediaButton)
        
        NSLayoutConstraint.activate([
            selectMediaButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectMediaButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            selectMediaButton.widthAnchor.constraint(equalToConstant: 150)
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
            let editorVC = EditorViewController(videoURL: videoURL)
            
            picker.dismiss(animated: true, completion: nil)
            self.navigationController?.pushViewController(editorVC, animated: true)
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
