// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CarMileage {
    struct Car {
        uint256 carId;
        uint256 lastMileage;
        uint256 lastMileageDate;
        address owner;
    }

    mapping(address => mapping(uint256 => Car)) public cars;
    mapping(address => uint256[]) public ownerCars;

    event MileageConfirmed(address indexed carOwner, uint256 carId, uint256 mileage, uint256 date);
    event CarOwnershipChanged(address indexed previousOwner, address indexed newOwner, uint256 carId);

    modifier onlyCarOwner(uint256 _carId) {
        require(ownerCars[msg.sender].length > 0, "You don't own any cars");
        bool isOwner = false;
        for (uint256 i = 0; i < ownerCars[msg.sender].length; i++) {
            if (ownerCars[msg.sender][i] == _carId) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "You don't own the specified car");
        _;
    }

    function addCar(uint256 _carId) external {
        Car storage newCar = cars[msg.sender][_carId];
        newCar.carId = _carId;
        newCar.owner = msg.sender;
        ownerCars[msg.sender].push(_carId);
    }

    function confirmMileage(uint256 _carId, uint256 _mileage) external onlyCarOwner(_carId) {
        Car storage car = cars[msg.sender][_carId];
        require(_mileage > car.lastMileage, "Mileage must be greater than the last confirmed mileage");
        require(block.timestamp > car.lastMileageDate, "Timestamp must be greater than the last confirmed timestamp");
        
        car.lastMileage = _mileage;
        car.lastMileageDate = block.timestamp;
        
        emit MileageConfirmed(msg.sender, _carId, _mileage, car.lastMileageDate);
    }

    function changeCarOwner(address _newOwner, uint256 _carId) external onlyCarOwner(_carId) {
        Car storage car = cars[msg.sender][_carId];
        require(car.owner != _newOwner, "The new owner must be different from the current owner");

        // Transfer ownership
        car.owner = _newOwner;
        // Clear ownership from the current owner's list
        for (uint256 i = 0; i < ownerCars[msg.sender].length; i++) {
            if (ownerCars[msg.sender][i] == _carId) {
                ownerCars[msg.sender][i] = ownerCars[msg.sender][ownerCars[msg.sender].length - 1];
                ownerCars[msg.sender].pop();
                break;
            }
        }
        // Add the car to the new owner's list
        ownerCars[_newOwner].push(_carId);

        emit CarOwnershipChanged(msg.sender, _newOwner, _carId);
    }

    function getMileage(uint256 _carId) external view onlyCarOwner(_carId) returns (uint256, uint256) {
        Car storage car = cars[msg.sender][_carId];
        return (car.lastMileage, car.lastMileageDate);
    }

    function listOwnerCars() external view returns (uint256[] memory) {
        return ownerCars[msg.sender];
    }
}
