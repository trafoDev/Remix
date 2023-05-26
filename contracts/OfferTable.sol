pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OfferTable {
    uint256 private _offerIndex; 

    mapping(uint256 => BondOfferDef) private _offers;
    mapping(address => mapping(uint256 => bool)) private _ownerOffers;

    struct BondOfferDef {
        address payable offerent;   // User who recieved tokens (if none - address(0))
        address payable bond2Sell; // Token offered by the sender
        uint256 amount2Sell;        // The number of tokens to give away
        uint256 bondDate;           // The number of tokens to receive
        bool    active;             // The number of tokens to receive
    }

    event OfferCreated(uint256 offerId);    
    event OfferFinalized(uint256 offerId);
    event OfferCanceled(uint256 offerId);

    modifier existing(uint256 _offerId) {
        require(isRegistered(_offerId), "Offer does not exist");
        _;
    }    
    //modifier refundable(uint256 _offerId) {
    //    require(offers[_offerId].sender == msg.sender, "Only the sender of this coin can cancel offer");
    //    require(offers[_offerId].recipient == address(0), "Already finalized or canceled");
    //    _;
    //}    
    //modifier claimable(uint256 _offerId) {
    //    require(offers[_offerId].recipient == address(0), "Already finalized or canceled");
    //    _;
    //}    
    constructor() {
       _offerIndex = 0;
    }
    function isRegistered(uint256 offerId) internal view returns (bool registered){
        registered = (_offers[offerId].offerent != address(0));
    }    
    function isActive(uint256 offerId) internal view returns (bool){
        return _offers[offerId].active;
    }    
    function newOffer( address bond2Sell, uint256 bondDate, uint256 amount2Sell) public  payable returns(uint256) {
//        require(_token2Sell == address(tokenA) || _token2Sell == address(tokenB), "Invalid token address");
//  it would be nice to check somehow if the address is pointing to the bond interface
        require(amount2Sell > 0, "Ammount must be greter than 0");
        require(bondDate > 20200101, "Invalid bond date");
        // Securing tokens as a deposit to cover the transaction
    //    if(!ERC20(_token2Sell).transferFrom(msg.sender, address(this), _amount2Sell)) revert("transfer failed");
        // Register the swap
        _offerIndex += 1;
        _offers[_offerIndex] = BondOfferDef({
            offerent : payable(msg.sender),
            bond2Sell : payable(bond2Sell),
            bondDate : bondDate,
            amount2Sell : amount2Sell,
            active : true
        });
        _ownerOffers[msg.sender][_offerIndex] = true;
        emit OfferCreated(_offerIndex);
        return _offerIndex;      
    }
    function cancelOffer(uint256 offerId) external existing(offerId) /*refundable(offerId)*/ returns(bool) {  
        BondOfferDef storage offer = _offers[offerId];
        require(offer.offerent == msg.sender, "Operation can be invoked by the bond's owner");
        // TODO: Change bond allocation... 
        //Tokens withdrawal from the deposit = closing the offer
        //!ERC20(s.token2Sell).transfer(s.sender, s.amount2Sell);
        offer.active = false; 
        _ownerOffers[msg.sender][offerId] = false;
        emit OfferCanceled(offerId);
        return true;
    }
    function finalizeOffer(uint256 offerId) public payable existing(offerId) /*claimable(_offerId)*/ returns(bool){
        BondOfferDef storage offer = _offers[offerId];
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