// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "./BondInterface.sol";
import "./EnvironmentConfig.sol";

error TableZeroAddress();

struct BondOfferDef {
    address bondSeller;   // User who sell bonds
    address bond2Sell;  // Bond offered 
    uint256 bondDate;           // Bond's date
    uint256 amount2Sell;        // The number of tokens to sell
    uint256 price;              // Price reqested in exchange
    bool    active;             // Active flag
}

contract OfferTable {
    uint256 private _offersNb; 

    EnvironmentConfig private _envConfig;
    BondOfferDef[] private _offers;
    mapping(address => mapping(uint256 => bool)) private _ownerOffers;

    event OfferCreated(uint256 offerId);    
    event OfferFinalized(uint256 offerId);
    event OfferCanceled(uint256 offerId);

    modifier existing(uint256 _offerId) {
        require(_isRegistered(_offerId), "Offer does not exist");
        _;
    }    
    modifier active(uint256 _offerId) {
        require(_isActive(_offerId), "Offer inactive");
        _;
    }    

    constructor( EnvironmentConfig config) {
        _offersNb = 0;
        _envConfig = config;
    }
    function _isRegistered(uint256 offerId) internal view returns (bool registered){
        registered = (_offers[offerId-1].bondSeller != address(0));
    }    
    function _isActive(uint256 offerId) internal view returns (bool){
        return _offers[offerId-1].active;
    }  
      
    function getOffers() public view returns (BondOfferDef[] memory) {
        return _offers;
    }

    function registerNewOffer(address seller, uint256 bondDate, uint256 amount2Sell, uint reqPrice) public  payable returns(uint256) {
        if(seller == address(0)) revert TableZeroAddress();
        require(amount2Sell > 0, "Ammount must be greter than 0");
        require(IERC20(msg.sender).balanceOf(seller) > amount2Sell, "Not enough bonds");
        require(bondDate > 20200101, "Invalid bond date");

        _offers.push(BondOfferDef({
            bondSeller : seller,
            bond2Sell : msg.sender,
            bondDate : bondDate,
            amount2Sell : amount2Sell,
            price : reqPrice,
            active : true
        }));
        _offersNb = _offers.length; //the model writes offers starting from id=0 - so index = nr of offers -1
        _ownerOffers[msg.sender][_offersNb] = true;
        emit OfferCreated(_offersNb);
        return _offersNb;      
    }

    function withdrawOffer(uint256 offerId) external existing(offerId) active(offerId) returns(BondOfferDef memory offer) {  
        require(_envConfig.isBlocked(msg.sender) == false, "User is blocked.");
        offer = _offers[offerId-1];
        require(offer.active == true, "Offer inactive");
        require(offer.bondSeller == msg.sender, "Operation can be invoked by seller");
        
        BondInterface(offer.bond2Sell).withdrawOffer(offer.bondSeller, offer.bondDate, offer.amount2Sell);

        _offers[offerId-1].active = false; 
        _ownerOffers[msg.sender][offerId-1] = false;
        emit OfferCanceled(offerId-1);
    }

    function acceptOffer(uint256 offerId, address money) public payable existing(offerId) active(offerId) returns(bool){
        require(_envConfig.isBlocked(msg.sender) == false, "User is blocked.");
        if(money == address(0)) revert TableZeroAddress();
        BondOfferDef memory offer = _offers[offerId-1];
        require(offer.active == true, "Offer inactive");
        require(_envConfig.isBlocked(offer.bondSeller) == false, "Bond seller is blocked.");
        address buyer = msg.sender;
        IERC20(money).transferFrom(msg.sender, offer.bondSeller, offer.price);

        BondInterface(offer.bond2Sell).acceptOffer(offer.bondSeller, buyer, offer.bondDate, offer.amount2Sell);

        _offers[offerId-1].active = false;
        _ownerOffers[msg.sender][offerId-1] = false;
        emit OfferFinalized(offerId);
        return true;
    }
}