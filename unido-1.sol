pragma solidity 0.7.0;

contract Ownable {
    address private _owner;
    address private _nextOwner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, 'Only the owner of the contract can do that');
        _;
    }
    
    function transferOwnership(address nextOwner) public onlyOwner {
        _nextOwner = nextOwner;
    }
    
    function takeOwnership() public {
        require(msg.sender == _nextOwner, 'Must be given ownership to do that');
        emit OwnershipTransferred(_owner, _nextOwner);
        _owner = _nextOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract UnidoDistribution is Ownable {
    using SafeMath for uint256;
    
    uint SEED_POOL = 1;
    uint PRIVATE_POOL = 2;
    uint TEAM_POOL = 3;
    uint ADVISOR_POOL = 4;
    uint ECOSYSTEM_POOL = 5;
    uint MINING_POOL = 6;
    uint RESERVE_POOL = 7;
    
    mapping (uint => uint) public pools;
    
    uint256 public totalSupply_;
    string public name = "Unido";
    uint256 public decimals = 18;
    string public symbol = "UDO";
    address[] public participants;
    
    uint256 private continuePoint = 0;
    uint256[] private deletions;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping(address => uint256)) public allowances;
    mapping (address => uint256) public lockoutPeriods;
    mapping (address => uint256) public lockoutBalances;
    mapping (address => uint256) public lockoutReleaseRates;
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Burn(address indexed tokenOwner, uint tokens);
    
    constructor () {
        pools[SEED_POOL] = 15000000 * 10**decimals;
        pools[PRIVATE_POOL] = 16000000 * 10**decimals;
        pools[TEAM_POOL] = 18400000 * 10**decimals;
        pools[ADVISOR_POOL] = 10350000 * 10**decimals;
        pools[ECOSYSTEM_POOL] = 14375000 * 10**decimals;
        pools[MINING_POOL] = 8625000 * 10**decimals;
        pools[RESERVE_POOL] = 32250000 * 10**decimals;

        totalSupply_ = pools[SEED_POOL] + pools[PRIVATE_POOL] + pools[TEAM_POOL] + pools[ADVISOR_POOL]
                    + pools[ECOSYSTEM_POOL] + pools[MINING_POOL] + pools[RESERVE_POOL];
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint) {
        return allowances[tokenOwner][spender];
    }
    
    function spendable(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner].sub(lockoutBalances[tokenOwner]);
    }
    
    function transfer(address to, uint tokens) public {
        require (balances[msg.sender].sub(lockoutBalances[msg.sender]) >= tokens, "Must have enough spendable tokens");
        require (tokens > 0, "Must transfer non-zero amount");
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
    }
    
    function approve(address spender, uint tokens) public {
        allowances[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
    }
    
    function burn(uint tokens) public {
        require (balances[msg.sender].sub(lockoutBalances[msg.sender]) >= tokens, "Must have enough spendable tokens");
        require (tokens > 0, "Must burn non-zero amount");
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        totalSupply_ = totalSupply_.sub(tokens);
        Burn(msg.sender, tokens);
    }
    
    function transferFrom(address from, address to, uint tokens) public {
        require (balances[msg.sender].sub(lockoutBalances[msg.sender]) >= tokens, "Must have enough spendable tokens");
        require (allowances[from][msg.sender] >= tokens, "Must be approved to spend that much");
        require (tokens > 0, "Must transfer non-zero amount");
        
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(tokens);
        Transfer(msg.sender, to, tokens);
    }
    
    function addParticipants(uint pool, address[] calldata _participants, uint256[] calldata _stakes) external onlyOwner {
        require (pool >= SEED_POOL && pool <= RESERVE_POOL, "Must select a valid pool");
        require (_participants.length == _stakes.length, "Must have equal array sizes");
        
        uint lockoutPeriod;
        uint lockoutReleaseRate;
        
        if (pool == SEED_POOL) {
            lockoutPeriod = 6;
            lockoutReleaseRate = 6;
        } else if (pool == PRIVATE_POOL) {
            lockoutPeriod = 4;
            lockoutReleaseRate = 6;
        } else if (pool == TEAM_POOL) {
            lockoutPeriod = 12;
            lockoutReleaseRate = 12;
        } else if (pool == ADVISOR_POOL) {
            lockoutPeriod = 6;
            lockoutReleaseRate = 6;
        } else if (pool == ECOSYSTEM_POOL) {
            lockoutPeriod = 3;
            lockoutReleaseRate = 12;
        } else if (pool == MINING_POOL) {
            lockoutPeriod = 0;
            lockoutReleaseRate = 6;
        } else if (pool == RESERVE_POOL) {
            lockoutPeriod = 0;
            lockoutReleaseRate = 18;
        }
        
        for (uint256 i = 0; i < _participants.length; i++) {
            require(lockoutBalances[_participants[i]] == 0, "Participants can't be involved in multiple lock ups simultaneously");
        
            participants.push(_participants[i]);
            lockoutBalances[_participants[i]] = _stakes[i];
            lockoutPeriods[_participants[i]] = lockoutPeriod;
            lockoutReleaseRates[_participants[i]] = lockoutReleaseRate;
        }
    }
    
    function finalizeParticipants(uint pool) external onlyOwner {
        uint leftover = pools[pool];
        pools[pool] = 0;
        totalSupply_ = totalSupply_.sub(leftover);
    }
    
    /**
     * For each account with an active lockout, if their lockout has expired 
     * then release their lockout at the lockout release rate
     * If the lockout release rate is 0, assume its all released at the date
     * Only do max 100 at a time, call repeatedly which it returns true
     */
    function updateRelease() external onlyOwner returns (bool continues) {
        uint scan = 100;
        
        for (uint i = continuePoint; i < participants.length && i < continuePoint.add(scan); i++) {
            address p = participants[i];
            if (lockoutPeriods[p] > 0) {
                lockoutPeriods[p]--;
            } else if (lockoutReleaseRates[p] > 0) {
                uint release = lockoutBalances[p].div(lockoutReleaseRates[p]);
                lockoutBalances[p] = lockoutBalances[p].sub(release);
                lockoutReleaseRates[p]--;
            } else {
                deletions.push(i);
            }
        }
        
        if (continuePoint.add(scan) >= participants.length) {
            continuePoint = 0;
            while (deletions.length > 0) {
                uint index = deletions[deletions.length-1];
                deletions.pop();
                
                participants[index] = participants[participants.length - 1];
                participants.pop();
            }
            return false;
        }
        
        return true;
    }
}