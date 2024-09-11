//
//  SearchViewController.swift
//  avito-unsplash-test
//
//  Created by Марк Кулик on 07.09.2024.
//

import UIKit

class SearchViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchResultsUpdating, UISearchBarDelegate, UICollectionViewDelegateFlowLayout {
    
    private enum LayoutMode {
        case oneColumn
        case twoColumns
    }
    
    private enum SortMode {
        case popularity
        case date
    }
    
    private enum ViewState {
           case content
           case error(String)
           case loading
           case loadingMore
       }
    
    // MARK: - Properties
    
    private var collectionView: UICollectionView!
    private var searchResults: [SearchResult] = []
    private var searchHistory: [SearchResult] = []
    private var filteredHistory: [SearchResult] = []
    private let apiClient = APIClient()
    private let maxHistoryCount = 5
    
    private var isShowingHistory = true
    private var layoutMode: LayoutMode = .twoColumns
    private var sortMode: SortMode = .popularity
    
    private var currentPage = 1
    private var isLoadingMoreResults = false
    
    private var searchDebounceTimer: Timer?
    
    private var viewState: ViewState = .loading {
        didSet {
            updateView(for: viewState)
        }
    }
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSearchController()
        setupViews()
        setupConstraints()
        setupButtons()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SearchCollectionViewCell.self, forCellWithReuseIdentifier: SearchCollectionViewCell.identifier)
        loadSearchHistory()
        viewState = .content
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let query = searchController.searchBar.text, !query.isEmpty {
            isShowingHistory = false
            filterSearchHistory(query: query)
        } else {
            isShowingHistory = true
            filteredHistory = searchHistory
        }
        collectionView.reloadData()
    }

    
    // MARK: - Setup Methods
    
    private func setupCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
           collectionView.dataSource = self
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.placeholder = "Search Photos"
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        print("SearchController setup: \(searchController)")
           print("SearchBar setup: \(searchController.searchBar)")
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(collectionView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func setupConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupButtons() {
        // Add layout button in UISearchBar
        searchController.searchBar.setImage(UIImage(systemName: "rectangle"), for: .bookmark, state: .normal)
        searchController.searchBar.showsBookmarkButton = true
        
        
        let filterButton = UIButton(type: .custom)
        if let logoImage = UIImage(named: "sort_icon") {
            filterButton.setImage(logoImage, for: .normal)
        }
        
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.addTarget(self, action: #selector(didTapFilterButton), for: .touchUpInside)
        
        filterButton.layer.cornerRadius = 25
        filterButton.layer.masksToBounds = true
        
        view.addSubview(filterButton)
        
        NSLayoutConstraint.activate([
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filterButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            filterButton.widthAnchor.constraint(equalToConstant: 50),
            filterButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
    }
    
    // MARK: - Action Methods
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func updateLayoutButton(for mode: LayoutMode) {
        let iconName: String
        switch mode {
        case .twoColumns:
            iconName = "rectangle"
        case .oneColumn:
            iconName = "rectangle.split.2x1"
        }

        if let iconImage = UIImage(systemName: iconName) {
            searchController.searchBar.setImage(iconImage, for: .bookmark, state: .normal)
        }
    }

    
    @objc private func didTapLayoutButton() {
        layoutMode = layoutMode == .twoColumns ? .oneColumn : .twoColumns
        updateLayoutButton(for: layoutMode)
        updateLayout()
    }
    
    @objc private func didTapFilterButton() {
        let alert = UIAlertController(title: "Sort by", message: nil, preferredStyle: .actionSheet)
        let popularityAction = UIAlertAction(title: "Popularity", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.sortMode = .popularity
            self.performSearch(self.searchController.searchBar.text ?? "")
        }
        let dateAction = UIAlertAction(title: "Date", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.sortMode = .date
            self.performSearch(self.searchController.searchBar.text ?? "")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(popularityAction)
        alert.addAction(dateAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Helper Methods
    
    private func updateLayout() {
        collectionView.setCollectionViewLayout(createLayout(), animated: true)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        let screenWidth = UIScreen.main.bounds.width
        let spacing: CGFloat = 10
        let numberOfItemsInRow: CGFloat = layoutMode == .twoColumns ? 2 : 1
        let totalSpacing = spacing * (numberOfItemsInRow - 1)
        let itemWidth = (screenWidth - totalSpacing - 2 * 5) / numberOfItemsInRow
        let itemHeight: CGFloat = layoutMode == .twoColumns ? 200 : 400
        
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        
        return layout
    }

    
    private func performSearch(_ query: String, reset: Bool = false) {
        if reset {
            currentPage = 1
            searchResults.removeAll()
        }
        
        guard !isLoadingMoreResults else { return }
        
        isLoadingMoreResults = true
        let sortBy = sortMode == .popularity ? "popularity" : "date"
        
        if !reset {
            viewState = .loadingMore
        }
        
        print("Performing search for query: \(query), page: \(currentPage)")
        
        apiClient.searchPhotos(query: query, sortBy: sortBy, page: currentPage) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let results):
                    if reset {
                        self.searchResults = results
                    } else {
                        self.searchResults.append(contentsOf: results)
                    }
                    self.viewState = .content
                    self.collectionView.reloadData()
                    self.currentPage += 1
                case .failure(let error):
                    self.viewState = .error(error.localizedDescription)
                }
                self.isLoadingMoreResults = false
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        
        if offsetY > contentHeight - frameHeight * 1.5, !isLoadingMoreResults, !isShowingHistory {
            performSearch(searchController.searchBar.text ?? "", reset: false)
        }
    }
    
    private func loadSearchHistory() {
        let defaults = UserDefaults.standard
        if let savedHistory = defaults.object(forKey: "searchHistory") as? Data {
            let decoder = JSONDecoder()
            if let history = try? decoder.decode([SearchResult].self, from: savedHistory) {
                searchHistory = history
            }
        }
        filteredHistory = searchHistory
        isShowingHistory = true
        collectionView.reloadData()
    }
    
    
    private func saveSearchResults(_ results: [SearchResult]) {
        if let result = results.first {
            searchHistory.insert(result, at: 0)
            if searchHistory.count > maxHistoryCount {
                searchHistory.removeLast()
            }
        }
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(searchHistory) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "searchHistory")
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func filterSearchHistory(query: String) {
        filteredHistory = searchHistory.filter {
            $0.description?.range(of: query, options: .caseInsensitive) != nil ||
            $0.user.name.range(of: query, options: .caseInsensitive) != nil
        }
        collectionView.reloadData()
    }
    
    private func saveSelectedResultToHistory(_ result: SearchResult) {
        // Проверяем, нет ли уже этой фотографии в истории
        if !searchHistory.contains(where: { $0.id == result.id }) {
            // Добавляем фото в начало истории
            searchHistory.insert(result, at: 0)
            
            // Ограничиваем количество элементов в истории
            if searchHistory.count > maxHistoryCount {
                searchHistory.removeLast()
            }
            
            // Сохраняем обновленную историю в UserDefaults
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(searchHistory) {
                let defaults = UserDefaults.standard
                defaults.set(encoded, forKey: "searchHistory")
            }
        }
    }
    
    private func updateView(for state: ViewState) {
           switch state {
           case .content:
               collectionView.isHidden = false
               collectionView.backgroundView = nil
           case .error(let message):
               collectionView.isHidden = true
               let errorView = UIView(frame: view.bounds)
               let label = UILabel()
               label.text = message
               label.textAlignment = .center
               errorView.addSubview(label)
               label.translatesAutoresizingMaskIntoConstraints = false
               NSLayoutConstraint.activate([
                   label.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
                   label.centerYAnchor.constraint(equalTo: errorView.centerYAnchor)
               ])
               collectionView.backgroundView = errorView
           case .loading:
               collectionView.isHidden = true
               let activityIndicator = UIActivityIndicatorView(style: .large)
               activityIndicator.startAnimating()
               collectionView.backgroundView = activityIndicator
           case .loadingMore:
               if let backgroundView = collectionView.backgroundView as? UIActivityIndicatorView {
                   backgroundView.startAnimating()
               } else {
                   let activityIndicator = UIActivityIndicatorView(style: .large)
                   activityIndicator.startAnimating()
                   collectionView.backgroundView = activityIndicator
               }
           }
       }
    
    // MARK: - Collection View Data Source Methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isShowingHistory ? filteredHistory.count : searchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
       
        let inset: CGFloat = 5
        return UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }


    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchCollectionViewCell.identifier, for: indexPath) as? SearchCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let result: SearchResult
        if indexPath.row < filteredHistory.count {
            result = filteredHistory[indexPath.row]
        } else {
            result = searchResults[indexPath.row - filteredHistory.count]
        }
        
        cell.configure(with: result)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedResult = isShowingHistory ? filteredHistory[indexPath.row] : searchResults[indexPath.row]
        
        saveSelectedResultToHistory(selectedResult)
        
        let detailVC = DetailViewController()
        detailVC.photoId = selectedResult.id
        detailVC.photoDescription = selectedResult.description
        detailVC.authorName = selectedResult.user.name
        detailVC.imageUrl = selectedResult.urls["regular"]
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - UISearchResultsUpdating Method
    
    internal func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text, !query.isEmpty else {
            isShowingHistory = true
            filteredHistory = searchHistory
            collectionView.reloadData()
            return
        }
        
        isShowingHistory = false
        filterSearchHistory(query: query)
        performSearch(query, reset: true)
    }
    
    
    // MARK: - UISearchBarDelegate Methods
    
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        didTapLayoutButton()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.performSearch(searchText, reset: true)
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if searchBar.text?.isEmpty == true {
            self.searchController.searchBar.text = ""
            isShowingHistory = true
            filteredHistory = searchHistory
            collectionView.reloadData()
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if searchBar.text?.isEmpty == true {
            filteredHistory = searchHistory
            collectionView.reloadData()
        } else {
            isShowingHistory = false
        }
        
        collectionView.reloadData()
    }
}
