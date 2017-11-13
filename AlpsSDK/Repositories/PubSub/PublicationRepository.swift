//
//  PublicationRepository.swift
//  AlpsSDK
//
//  Created by Maciej Burda on 27/10/2017.
//  Copyright © 2017 Alps. All rights reserved.
//

import Foundation
import Alps

let kPublicationFile = "kPublicationFile.Alps"

final public class PublicationRepository: AsyncCreateable, AsyncReadable, AsyncDeleteable, AsyncClearable {
    
    typealias DataType = Publication
    
    private(set) var items: [Publication] {
        get {
            return _items.withoutExpired
        }
        set {
            _items = newValue
        }
    }
    
    private var _items = [Publication]() {
        didSet {
            _ = PersistenceManager.save(object: self._items.withoutExpired.map { $0.encodablePublication }, to: kPublicationFile)
        }
    }
    
    init() {
        self.items = PersistenceManager.read(type: [EncodablePublication].self, from: kPublicationFile)?.map { $0.object }.withoutExpired ?? []
    }
    
    func create(item: Publication, completion: @escaping (Result<Publication?>) -> Void) {
        guard let deviceId = item.deviceId else { return }
        PublicationAPI.createPublication(deviceId: deviceId, publication: item) { (publication, error) in
            if let publication = publication, error == nil {
                self.items.append(publication)
                completion(.success(publication))
            } else {
                completion(.failure(error as? ErrorResponse))
            }
        }
    }
    
    public func find(byId: String, completion: @escaping (Result<Publication?>) -> Void) {
        completion(.success(items.filter { $0.id == byId }.first))
    }
    
    public func findAll(completion: @escaping (Result<[Publication]>) -> Void) {
        completion(.success(items))
    }
    
    public func delete(item: Publication, completion: @escaping (ErrorResponse?) -> Void) {
        guard let id = item.id else { completion(ErrorResponse.missingId); return }
        guard let deviceId = item.deviceId else { completion(ErrorResponse.missingId); return }
        PublicationAPI.deletePublication(deviceId: deviceId, publicationId: id, completion: { (error) in
            if error == nil {
                self.items = self.items.filter { $0.id != id }
            }
            completion(error as? ErrorResponse)
        })
    }
}

extension PublicationRepository: DeviceDeleteDelegate {
    func didDeleteDeviceWith(id: String) {
        self.items = self.items.filter { $0.deviceId != id }
    }
}
