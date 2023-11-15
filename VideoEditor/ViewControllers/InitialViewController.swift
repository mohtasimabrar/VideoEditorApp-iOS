//
//  ViewController.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 9/11/23.
//

import UIKit

class InitialViewController: UIViewController, UINavigationControllerDelegate {
    
    private lazy var selectMediaButton: UIButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.tintColor = UIColor(hex: "#9B5AFA")
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.addTarget(self, action: #selector(selectMediaButtonTapped), for: .touchUpInside)
        
        return $0
    }(UIButton())
    
    private lazy var starterLabel: UILabel = {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .light)
        $0.textAlignment = .center
        $0.numberOfLines = 1
        $0.textColor = .gray
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.text = "Tap the plus icon to open a video"
        
        return $0
    }(UILabel())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = " "
        view.backgroundColor = .white
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func setupView() {
        view.addSubview(selectMediaButton)
        view.addSubview(starterLabel)
        
        NSLayoutConstraint.activate([
            selectMediaButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectMediaButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            selectMediaButton.widthAnchor.constraint(equalToConstant: 100),
            selectMediaButton.heightAnchor.constraint(equalToConstant: 100),
            
            starterLabel.topAnchor.constraint(equalTo: selectMediaButton.bottomAnchor, constant: 30),
            starterLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            starterLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
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

extension InitialViewController: UIImagePickerControllerDelegate {
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
