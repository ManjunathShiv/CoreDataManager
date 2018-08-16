//
//  CoreDataManager.swift
//  CoreDataManager
//
//  Created by Manjunath Shivakumara on 23/02/18.
//  Copyright © 2018 Manjunath Shivakumara. All rights reserved.
//

import Foundation
import CoreData

import Foundation
import CoreData

/**
 The CoreDataManagerDataSource protocol. This protocol will use to get information from client application.
 
 @since 1.0.0
 */
public protocol CoreDataManagerDataSource: class {
    
    /**
     Fetch core data modelName from client application.
     
     @return A CoreDataModel String.
     
     @since 1.0.0
     */
    func modelName(for coreDataManager: CoreDataManager) -> String?
}


/**
 The CoreDataManager class. This class will have InsertNewObject, UpdateObject, FetchObjects, DeleteObject operations.
 
 @since 1.0.0
 */
open class CoreDataManager {
    /**
     Shared Instance of CoreDataManager.
     
     @since 1.0.0
     */
    static open let shared = CoreDataManager()
    
    /**
     CoreData modelName, in which CoreDataManager will use to store details.
     
     @note This is read-only variable.
     
     @since 1.0.0
     */
    open var modelName: String? {
        return dataSource?.modelName(for: self)
    }
    
    /**
     CoreDataManagerDataSource instance: will use to get information from client application.
     
     @since 1.0.0
     */
    open weak var dataSource: CoreDataManagerDataSource?
    
    
    // Private Init because this class is a singleton class.
    private init() {}
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer? = {
        guard let modelName = modelName else { return nil }
        let container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
}

extension CoreDataManager {
    // MARK: - Core Data Saving support
    open func save() {
        guard let context = persistentContainer?.viewContext else { return }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

public extension CoreDataManager {
    /**
     Insert New Object.
     
     @since 1.0.0
     */
    @discardableResult
    //If Duplicates Are Allowed
    public func insertNewObject(forEntityName entityName: String, data: Dictionary<String, Any>, instantSave: Bool) -> NSManagedObject? {
        guard let context = persistentContainer?.viewContext else { return nil}
        
        let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        return updateObject(managedObject, data: data, instantSave: instantSave)
    }
    
    @discardableResult
    //If Duplicates Are Not Allowed
    public func insertNewObjectAfterCheckingForDuplicate(forEntityName entityName: String, predicate : NSPredicate, data: Dictionary<String, Any>, instantSave: Bool) -> NSManagedObject? {
        guard let context = persistentContainer?.viewContext else { return nil}
        
        let request: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = predicate
        request .returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(request)
            if results.count == 0 {
                let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
                return updateObject(managedObject, data: data, instantSave: instantSave)
            }
        } catch {}
        return nil
    }
    
    
    /**
     Update Object.
     
     @since 1.0.0
     */
    @discardableResult
    public func updateObject(_ managedObject: NSManagedObject, data: Dictionary<String, Any>, instantSave: Bool) -> NSManagedObject {
        let keys = managedObject.entity.attributesByName.keys
        for key in keys {
            if let value = data[key] {
                managedObject.setValue(value, forKey: key)
            }
        }
        if instantSave { save() }
        return managedObject
    }
    
    /**
     Fetch Objects.
     
     @since 1.0.0
     */
    @discardableResult
    public func fetchObjects(forEntityName entityName: String, predicate: NSPredicate? = nil, sortDescriptors: Array<NSSortDescriptor>? = nil) ->Array<Any>? {
        guard let context = persistentContainer?.viewContext else { return nil}
        let request: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = predicate
        request .returnsObjectsAsFaults = false
        
        request.sortDescriptors = sortDescriptors
        do {
            return try context.fetch(request)
        } catch {
            return nil
        }
    }
    
    /**
     Delete Object.
     
     @since 1.0.0
     */
    public func deleteObject(_ managedObject: NSManagedObject, instantSave: Bool) {
        guard let context = persistentContainer?.viewContext else { return }
        context.delete(managedObject)
        if instantSave { save() }
    }
    
    
    /**
     Delete All Objects.
     
     @since 1.0.0
     */
    public func deleteAllObjects(forEntityName entityName: String, instantSave: Bool) {
        guard let context = persistentContainer?.viewContext else { return }
        let results = self.fetchObjects(forEntityName: entityName) ?? []
        for result in results {
            guard let result = result as? NSManagedObject else { return }
            context.delete(result)
        }
        if instantSave { save() }
    }
}
