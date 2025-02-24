import Photos
import SwiftUI

class PhotoManager: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var photosByDate: [Date: [PHAsset]] = [:]
    
    init() {
        checkAuthorization()
    }
    
    func checkAuthorization() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if authorizationStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {
                    self?.authorizationStatus = status
                    if status == .authorized {
                        self?.fetchPhotos()
                    }
                }
            }
        } else if authorizationStatus == .authorized {
            fetchPhotos()
        }
    }
    
    func fetchPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var tempPhotosByDate: [Date: [PHAsset]] = [:]
        
        allPhotos.enumerateObjects { (asset, index, stop) in
            if let date = asset.creationDate {
                let calendar = Calendar.current
                let normalizedDate = calendar.startOfDay(for: date)
                if tempPhotosByDate[normalizedDate] == nil {
                    tempPhotosByDate[normalizedDate] = []
                }
                tempPhotosByDate[normalizedDate]?.append(asset)
            }
        }
        
        DispatchQueue.main.async {
            self.photosByDate = tempPhotosByDate
        }
    }
    
    func loadThumbnail(for asset: PHAsset, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            completion(image)
        }
    }
} 