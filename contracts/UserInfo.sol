// SPDX-License-Identifier: BLANK
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract UserDb is ReentrancyGuard, Ownable, AccessControl {
    uint256 public currentEntry; // This variable counts the amount of users registered
    // currentEntry++ , this increments the integer by 1

    struct userAccount {
        string accountCid;  // ipfs path to the user profile data
        address userId;     // user browser wallet (like mmask) address
        address payWallet;  // user site (platform) wallet
        uint256 userNum;
    }

    mapping(address => userAccount) public _account;

    struct userNumber {
        address bwsWallet;
    }

    mapping(uint256 => userNumber) public _entry;

    //  since profile picture might be changed many times, it is better to make it a special struct
    struct userPicture {
        string pictureCid;  // from ipfs
    }

    mapping(address => userPicture) public _picture;

    struct erc20Pay {
        uint256 lastPaid;
    }

    mapping(address => erc20Pay) public _ercPay;

    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(UPDATER_ROLE, _msgSender());
    }

    
    function generateProfile(string memory newCid, address wallet, address payErcWallet)
    external
    nonReentrant
    {
     require(hasRole(UPDATER_ROLE, _msgSender()), "You must have updater role to run");
     
     currentEntry++;

     _account[wallet] = userAccount({
        accountCid: newCid,
        userId: wallet,
        userNum: currentEntry,
        payWallet: payErcWallet
        });

    _entry[currentEntry] = userNumber({
         bwsWallet: wallet
        });

    }

    function updateProfile(string memory newCid, address wallet)
    external
    nonReentrant
    {
      require(hasRole(UPDATER_ROLE, _msgSender()), "You must have updater role to run");
      // when you wanna update a struct, you should update all the properties even if they are the same 
      address ercWallet = _account[msg.sender].payWallet;
      uint256 usernumber = _account[msg.sender].userNum;
      _account[wallet] = userAccount({
        accountCid: newCid,
        userId: wallet,
        payWallet: ercWallet,
        userNum: usernumber
        });
    }

    function updatePicture(string memory newCid, address wallet)
        external
        nonReentrant
        {
        require(hasRole(UPDATER_ROLE, _msgSender()), "You must have updater role to run");

        _picture[wallet] = userPicture({
            pictureCid: newCid
        });
        }

    function recordPay(uint256 lastPay, address wallet)
        external
        nonReentrant
        {
        require(hasRole(UPDATER_ROLE, _msgSender()), "You must have updater role to run");

        _ercPay[wallet] = erc20Pay({
            lastPaid: lastPay
            });
        }

    function migrateProfile(address newWallet)
    external
    nonReentrant
    {
      require(_account[msg.sender].userId == msg.sender, "Account not found");
      require(_account[msg.sender].userId != newWallet, "Wallet already exists");
      uint256 previousId = _account[msg.sender].userNum;
      _entry[previousId] = userNumber({
        bwsWallet: newWallet
        });
      string memory migrateUserCid = _account[msg.sender].accountCid;
      address ercWallet = _account[msg.sender].payWallet;
      _account[newWallet] = userAccount({
        accountCid: migrateUserCid,
        userId: newWallet,
        payWallet: ercWallet,
        userNum: previousId
        });
        delete _account[msg.sender];
        string memory migratePicCid = _picture[msg.sender].pictureCid;
        _picture[newWallet] = userPicture({
            pictureCid: migratePicCid
       });
       delete _picture[msg.sender];
       uint256 lastPaidTime = _ercPay[msg.sender].lastPaid;
       _ercPay[newWallet] = erc20Pay({
            lastPaid: lastPaidTime
       });
       delete _ercPay[msg.sender];
    }


    function deleteProfile()
        external
        nonReentrant
        {
        require(_account[msg.sender].userId == msg.sender, "Account not found");
        uint256 previousId = _account[msg.sender].userNum;
        delete _entry[previousId];
        delete _account[msg.sender];
        delete _picture[msg.sender];
        delete _ercPay[msg.sender];
        }

    function confirmUser() external view returns (address){
            address userWallet = _account[msg.sender].userId;
            return userWallet;
        }


}