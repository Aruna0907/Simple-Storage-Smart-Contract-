// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Project {
    address public owner;
    uint256 public totalRecords;
    
    // Storage structure for data records
    struct StorageRecord {
        uint256 id;
        string key;
        string value;
        address creator;
        uint256 timestamp;
        bool isActive;
        string category;
        uint256 version;
    }
    
    // Mappings for efficient data storage and retrieval
    mapping(uint256 => StorageRecord) public records;
    mapping(string => uint256) public keyToRecordId;
    mapping(address => uint256[]) public userRecords;
    mapping(string => uint256[]) public categoryRecords;
    
    // Arrays for iteration
    uint256[] public recordIds;
    string[] public allKeys;
    
    // Events for logging activities
    event DataStored(
        uint256 indexed recordId,
        string indexed key,
        string value,
        address indexed creator,
        uint256 timestamp
    );
    
    event DataUpdated(
        uint256 indexed recordId,
        string indexed key,
        string oldValue,
        string newValue,
        address indexed updater,
        uint256 timestamp
    );
    
    event DataDeleted(
        uint256 indexed recordId,
        string indexed key,
        address indexed deleter,
        uint256 timestamp
    );
    
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner,
        uint256 timestamp
    );
    
    // Modifiers for access control and validation
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier validRecordId(uint256 _recordId) {
        require(records[_recordId].id != 0, "Record does not exist");
        _;
    }
    
    modifier onlyCreatorOrOwner(uint256 _recordId) {
        require(
            msg.sender == records[_recordId].creator || msg.sender == owner,
            "Only record creator or owner can perform this action"
        );
        _;
    }
    
    modifier activeRecord(uint256 _recordId) {
        require(records[_recordId].isActive, "Record is not active");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        totalRecords = 0;
    }
    
    /**
     * @dev Store new data with key-value pair
     * @param _key Unique identifier for the data
     * @param _value Data value to store
     * @param _category Category for organizing data
     * @return recordId The unique ID of the stored record
     */
    function storeData(
        string memory _key,
        string memory _value,
        string memory _category
    ) external returns (uint256) {
        require(bytes(_key).length > 0, "Key cannot be empty");
        require(bytes(_value).length > 0, "Value cannot be empty");
        require(keyToRecordId[_key] == 0, "Key already exists");
        
        totalRecords++;
        uint256 newRecordId = totalRecords;
        
        records[newRecordId] = StorageRecord({
            id: newRecordId,
            key: _key,
            value: _value,
            creator: msg.sender,
            timestamp: block.timestamp,
            isActive: true,
            category: _category,
            version: 1
        });
        
        keyToRecordId[_key] = newRecordId;
        userRecords[msg.sender].push(newRecordId);
        recordIds.push(newRecordId);
        allKeys.push(_key);
        
        if (bytes(_category).length > 0) {
            categoryRecords[_category].push(newRecordId);
        }
        
        emit DataStored(newRecordId, _key, _value, msg.sender, block.timestamp);
        
        return newRecordId;
    }
    
    /**
     * @dev Update existing data value
     * @param _recordId Record ID to update
     * @param _newValue New value to store
     */
    function updateData(
        uint256 _recordId,
        string memory _newValue
    ) external validRecordId(_recordId) onlyCreatorOrOwner(_recordId) activeRecord(_recordId) {
        require(bytes(_newValue).length > 0, "New value cannot be empty");
        
        StorageRecord storage record = records[_recordId];
        string memory oldValue = record.value;
        
        record.value = _newValue;
        record.timestamp = block.timestamp;
        record.version++;
        
        emit DataUpdated(_recordId, record.key, oldValue, _newValue, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Retrieve data by record ID
     * @param _recordId Record ID to retrieve
     * @return Complete record information
     */
    function getData(uint256 _recordId) external view validRecordId(_recordId) activeRecord(_recordId) returns (
        uint256 id,
        string memory key,
        string memory value,
        address creator,
        uint256 timestamp,
        bool isActive,
        string memory category,
        uint256 version
    ) {
        StorageRecord storage record = records[_recordId];
        return (
            record.id,
            record.key,
            record.value,
            record.creator,
            record.timestamp,
            record.isActive,
            record.category,
            record.version
        );
    }
    
    /**
     * @dev Get data by key
     * @param _key Key to search for
     * @return value The stored value
     * @return recordId The record ID
     * @return creator Address of the creator
     * @return timestamp When the data was last updated
     */
    function getDataByKey(string memory _key) external view returns (
        string memory value,
        uint256 recordId,
        address creator,
        uint256 timestamp
    ) {
        uint256 id = keyToRecordId[_key];
        require(id != 0, "Key does not exist");
        require(records[id].isActive, "Record is not active");
        
        StorageRecord storage record = records[id];
        return (record.value, id, record.creator, record.timestamp);
    }
    
    /**
     * @dev Delete/deactivate a record
     * @param _recordId Record ID to delete
     */
    function deleteData(
        uint256 _recordId
    ) external validRecordId(_recordId) onlyCreatorOrOwner(_recordId) activeRecord(_recordId) {
        records[_recordId].isActive = false;
        records[_recordId].timestamp = block.timestamp;
        
        emit DataDeleted(_recordId, records[_recordId].key, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Get all records created by a specific user
     * @param _user User address
     * @return recordIds Array of record IDs created by the user
     */
    function getUserRecords(address _user) external view returns (uint256[] memory) {
        return userRecords[_user];
    }
    
    /**
     * @dev Get all records in a specific category
     * @param _category Category name
     * @return recordIds Array of record IDs in the category
     */
    function getRecordsByCategory(string memory _category) external view returns (uint256[] memory) {
        return categoryRecords[_category];
    }
    
    /**
     * @dev Get all active records
     * @return activeRecordIds Array of active record IDs
     */
    function getActiveRecords() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active records
        for (uint256 i = 0; i < recordIds.length; i++) {
            if (records[recordIds[i]].isActive) {
                activeCount++;
            }
        }
        
        // Create array of active record IDs
        uint256[] memory activeRecordIds = new uint256[](activeCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 0; i < recordIds.length; i++) {
            if (records[recordIds[i]].isActive) {
                activeRecordIds[currentIndex] = recordIds[i];
                currentIndex++;
            }
        }
        
        return activeRecordIds;
    }
    
    /**
     * @dev Get all keys in the storage
     * @return Array of all keys
     */
    function getAllKeys() external view returns (string[] memory) {
        return allKeys;
    }
    
    /**
     * @dev Check if a key exists
     * @param _key Key to check
     * @return exists Whether the key exists
     * @return isActive Whether the associated record is active
     */
    function keyExists(string memory _key) external view returns (bool exists, bool isActive) {
        uint256 recordId = keyToRecordId[_key];
        exists = recordId != 0;
        isActive = exists && records[recordId].isActive;
        return (exists, isActive);
    }
    
    /**
     * @dev Get total number of records
     * @return Total record count
     */
    function getTotalRecords() external view returns (uint256) {
        return totalRecords;
    }
    
    /**
     * @dev Get number of active records
     * @return Active record count
     */
    function getActiveRecordCount() external view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < recordIds.length; i++) {
            if (records[recordIds[i]].isActive) {
                activeCount++;
            }
        }
        return activeCount;
    }
    
    /**
     * @dev Get record history/metadata
     * @param _recordId Record ID
     * @return creator Address of creator
     * @return timestamp Last update timestamp
     * @return version Current version number
     * @return category Record category
     */
    function getRecordMetadata(uint256 _recordId) external view validRecordId(_recordId) returns (
        address creator,
        uint256 timestamp,
        uint256 version,
        string memory category
    ) {
        StorageRecord storage record = records[_recordId];
        return (record.creator, record.timestamp, record.version, record.category);
    }
    
    /**
     * @dev Bulk store multiple key-value pairs
     * @param _keys Array of keys
     * @param _values Array of values
     * @param _category Category for all records
     * @return recordIds Array of created record IDs
     */
    function bulkStore(
        string[] memory _keys,
        string[] memory _values,
        string memory _category
    ) external returns (uint256[] memory) {
        require(_keys.length == _values.length, "Keys and values length mismatch");
        require(_keys.length > 0, "Arrays cannot be empty");
        
        uint256[] memory newRecordIds = new uint256[](_keys.length);
        
        for (uint256 i = 0; i < _keys.length; i++) {
            newRecordIds[i] = this.storeData(_keys[i], _values[i], _category);
        }
        
        return newRecordIds;
    }
    
    /**
     * @dev Transfer contract ownership
     * @param _newOwner Address of new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner must be different");
        
        address previousOwner = owner;
        owner = _newOwner;
        
        emit OwnershipTransferred(previousOwner, _newOwner, block.timestamp);
    }
    
    /**
     * @dev Emergency function to reactivate a record (owner only)
     * @param _recordId Record ID to reactivate
     */
    function reactivateRecord(uint256 _recordId) external onlyOwner validRecordId(_recordId) {
        require(!records[_recordId].isActive, "Record is already active");
        
        records[_recordId].isActive = true;
        records[_recordId].timestamp = block.timestamp;
    }
    
    /**
     * @dev Get contract statistics
     * @return totalRecords Total number of records
     * @return activeRecords Number of active records
     * @return totalUsers Number of unique users
     * @return contractOwner Address of contract owner
     */
    function getContractStats() external view returns (
        uint256 totalRecords_,
        uint256 activeRecords,
        uint256 totalUsers,
        address contractOwner
    ) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < recordIds.length; i++) {
            if (records[recordIds[i]].isActive) {
                activeCount++;
            }
        }
        
        // Note: totalUsers would require additional tracking for exact count
        // This is a simplified version
        return (totalRecords, activeCount, recordIds.length, owner);
    }
}
