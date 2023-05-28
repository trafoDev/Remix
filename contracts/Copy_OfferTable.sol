// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "./BondInterface.sol";
//import "./BaseBondToken.sol";

error ZeroAddress();

struct BondOfferDef {
    address payable offerent;   // User who recieved tokens (if none - address(0))
    address payable bond2Sell;  // Token offered by the sender
    uint256 amount2Sell;        // The number of tokens to give away
    uint256 bondDate;           // The number of tokens to receive
    uint256 price;           // The number of tokens to receive
    bool    active;             // The number of tokens to receive
}

contract OfferTable {
    uint256 private _offersNb; 

    mapping(uint256 => BondOfferDef) private _offers;
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

    constructor() {
       _offersNb = 0;
    }
    function _isRegistered(uint256 offerId) internal view returns (bool registered){
        registered = (_offers[offerId].offerent != address(0));
    }    
    function _isActive(uint256 offerId) internal view returns (bool){
        return _offers[offerId].active;
    }    
    function getOffers() public returns (BondOfferDef[] memory offers) {
        BondOfferDef[]  offers1;
        for(uint i=0; i < _offersNb; i++) {
            if( _isActive(i+1)) {
                offers1.push(_offers[i+1]);
            } 
        }
        return offers;
    }

    function newOffer(address seller, uint256 bondDate, uint256 amount2Sell, uint reqPrice) public  payable returns(uint256) {
        if(seller == address(0)) revert ZeroAddress();
//  it would be nice to check somehow if the address is pointing to the bond interface
        require(amount2Sell > 0, "Ammount must be greter than 0");
        require(IERC20(msg.sender).balanceOf(seller) > amount2Sell, "Not enough bonds");
        require(bondDate > 20200101, "Invalid bond date");
        // Securing tokens as a deposit to cover the transaction
    //    if(!ERC20(_token2Sell).transferFrom(msg.sender, address(this), _amount2Sell)) revert("transfer failed");
        // Register the swap

        _offersNb += 1; //the model writes offers starting from id=1 - so index = nr of offers

        _offers[_offersNb] = BondOfferDef({
            offerent : payable(seller),
            bond2Sell : payable(msg.sender),
            bondDate : bondDate,
            amount2Sell : amount2Sell,
            price : reqPrice,
            active : true
        });
        _ownerOffers[msg.sender][_offersNb] = true;
        emit OfferCreated(_offersNb);
        return _offersNb;      
    }

    function cancelOffer(uint256 offerId) external existing(offerId) active(offerId) returns(BondOfferDef memory offer) {  
        offer = _offers[offerId];
//        require(offer.offerent == msg.sender, "Operation can be invoked by the bond's owner");
        require(offer.active == true, "Offer inactive");
        require(offer.bond2Sell == msg.sender, "Operation can be invoked by the bond");
        // TODO: Change bond allocation... 
        //Tokens withdrawal from the deposit = closing the offer
        //!ERC20(s.token2Sell).transfer(s.sender, s.amount2Sell);
        _offers[offerId].active = false; 
        _ownerOffers[msg.sender][offerId] = false;
        emit OfferCanceled(offerId);
    }

    function finalizeOffer(uint256 offerId, address money) public payable existing(offerId) active(offerId) returns(bool){
        if(money == address(0)) revert ZeroAddress();
        BondOfferDef memory offer = _offers[offerId];
        require(offer.active == true, "Offer inactive");
        address buyer = msg.sender;
        IERC20(money).transferFrom(msg.sender, offer.offerent, offer.price);
        BondInterface(offer.bond2Sell).transferFrom(offer.offerent, buyer, offer.bondDate, offer.amount2Sell);
        _offers[offerId].active = false;
        _ownerOffers[msg.sender][offerId] = false;




        //BondOfferDef storage offer = _offers[offerId];
//        IERC20 token2Buy = (s.token2Sell == address(tokenA)) ? tokenB : tokenA;
  //      require(token2Buy.allowance(msg.sender, address(this)) >= s.amount2Buy, "Not enough allowance");
        // Transfer the required number of tokens to the offer-creating party
        //if( !token2Buy.transferFrom(msg.sender, offer.sender, offer.amount2Buy)) revert("transfer failed");
        // Transfer token from a deposit from the sender to the counterparty
        //if( !ERC20(s.token2Sell).transfer(msg.sender, offer.amount2Sell)) revert("transfer failed");
        //offer.recipient = payable(msg.sender);
        emit OfferFinalized(offerId);
        return true;
    }
}