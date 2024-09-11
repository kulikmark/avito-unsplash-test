//
//  DetailViewController.swift
//  avito-unsplash-test
//
//  Created by Марк Кулик on 07.09.2024.
//

import UIKit

class DetailViewController: UIViewController {
    
    var photoId: String?
    var photoDescription: String?
    var authorName: String?
    var imageUrl: String?
    
    private let imageView = UIImageView()
    private let descriptionLabel = UILabel()
    private let authorLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    private enum ViewState {
        case content
        case error(String)
        case loading
    }
    
    private var viewState: ViewState = .loading {
        didSet {
            updateViewForState()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupNavigationBar()
        displayPhotoDetails()
    }
    
    private func setupNavigationBar() {
        let shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(sharePhoto)
        )
        
        let saveButton = UIBarButtonItem(
            title: "Save",
            style: .plain,
            target: self,
            action: #selector(savePhoto)
        )
        
        navigationItem.rightBarButtonItems = [shareButton, saveButton]
    }
    
    private func displayPhotoDetails() {
        viewState = .loading
        
        guard let imageUrl = imageUrl, let url = URL(string: imageUrl) else {
            viewState = .error("Invalid image URL")
            return
        }
        
        descriptionLabel.text = photoDescription
        authorLabel.text = authorName
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.viewState = .error(error.localizedDescription)
                }
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.viewState = .error("Failed to load image")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.imageView.image = image
                self.viewState = .content
            }
        }.resume()
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(imageView)
        view.addSubview(descriptionLabel)
        view.addSubview(authorLabel)
        view.addSubview(activityIndicator)
        
        imageView.contentMode = .scaleAspectFit
        descriptionLabel.numberOfLines = 0
        activityIndicator.hidesWhenStopped = true
    }
    
    private func setupConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 300),
            
            descriptionLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            authorLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10),
            authorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            authorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func updateViewForState() {
        switch viewState {
        case .content:
            activityIndicator.stopAnimating()
            imageView.isHidden = false
            descriptionLabel.isHidden = false
            authorLabel.isHidden = false
        case .error(let message):
            activityIndicator.stopAnimating()
            imageView.isHidden = true
            descriptionLabel.isHidden = true
            authorLabel.isHidden = true
            showAlert(title: "Error", message: message)
        case .loading:
            activityIndicator.startAnimating()
            imageView.isHidden = true
            descriptionLabel.isHidden = true
            authorLabel.isHidden = true
        }
    }
    
    @objc private func sharePhoto() {
        guard let image = imageView.image else { return }
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }
    
    @objc private func savePhoto() {
        guard let image = imageView.image else { return }
        
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
        } else {
            showAlert(title: "Saved", message: "Photo has been saved to your photos.")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
