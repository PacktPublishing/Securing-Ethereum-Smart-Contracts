
pragma solidity 0.4.25;

contract walletLibrary {
    
    // multi-sig function modifier: the operation must have an intrinsic hash in order
    // that later attempts can be realised as the same underlying operation and
    // thus count as confirmations.
    modifier onlymanyowners(bytes32 _operation) {
        // determine what index the present sender is:
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
        // make sure they're an owner
        if (ownerIndex == 0) return;
        _;
    }
    
    // kills the contract sending everything to `_to`.
    function kill(address _to) onlymanyowners(sha3(msg.data)) external {
        selfdestruct(_to);
    }

    
    // constructor is given number of sigs required to do protected "onlymanyowners" transactions
    // as well as the selection of addresses capable of confirming them.
    function initMultiowned(address[] _owners, uint _required) {
        m_numOwners = _owners.length + 1;
        m_owners[1] = uint(msg.sender);
        m_ownerIndex[uint(msg.sender)] = 1;
        for (uint i = 0; i < _owners.length; ++i)
        {
            m_owners[2 + i] = uint(_owners[i]);
          m_ownerIndex[uint(_owners[i])] = 2 + i;
        }
        m_required = _required;
    }
    
    // constructor - stores initial daily limit and records the present day's index.
    function initDaylimit(uint _limit) {
        m_dailyLimit = _limit;
        m_lastDay = now / 1 days;
    }
    
    // constructor - just pass on the owner array to the multiowned and  // the limit to daylimit  
    function initWallet(address[] _owners, uint _required, uint _daylimit) {    
        initDaylimit(_daylimit);    
        initMultiowned(_owners, _required);  
    }    
    
  // FIELDS

  // the number of owners that must confirm the same operation before it is run.
  uint public m_required;
  // pointer used to find a free slot in m_owners
  uint public m_numOwners;

  uint public m_dailyLimit;
  uint public m_spentToday;
  uint public m_lastDay;

  // list of owners
  uint[256] m_owners;
  
  // index on the list of owners to allow reverse lookup
  mapping(uint => uint) m_ownerIndex;
}
contract Wallet {

  // WALLET CONSTRUCTOR
  //   calls the `initWallet` method of the Library in this context
  function Wallet(address[] _owners, uint _required, uint _daylimit, walletLibrary _externalLibrary) {
    _walletLibrary = _externalLibrary;
    // Signature of the Wallet Library's init function
    bytes4 sig = bytes4(sha3("initWallet(address[],uint256,uint256)"));
    _walletLibrary.initWallet(_owners, _required, _daylimit);
    
  }

  // METHODS

  // gets called when no other function matches
  function() payable {
      _walletLibrary.delegatecall(msg.data);
  }

  // Gets an owner by 0-indexed position (using numOwners as the count)
  function getOwner(uint ownerIndex) constant returns (address) {
    return address(m_owners[ownerIndex + 1]);
  }

  // As return statement unavailable in fallback, explicit the method here

  function hasConfirmed(bytes32 _operation, address _owner) external constant returns (bool) {
    return _walletLibrary.delegatecall(msg.data);
  }

  function isOwner(address _addr) constant returns (bool) {
    return _walletLibrary.delegatecall(msg.data);
  }

  // FIELDS
  walletLibrary _walletLibrary;

  // the number of owners that must confirm the same operation before it is run.
  uint public m_required;
  // pointer used to find a free slot in m_owners
  uint public m_numOwners;

  uint public m_dailyLimit;
  uint public m_spentToday;
  uint public m_lastDay;

  // list of owners
  uint[256] m_owners;
}
