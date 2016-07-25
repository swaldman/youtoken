contract YouToken {

   /*
    *  Members
    */

   // owner => ( issuer => balance )
   mapping(address => mapping(address => uint)) public balances;

   // issuer => float
   mapping(address => uint) public floats;

   /*
    *  Events
    */

   event Issuance(address indexed recipient, address indexed issuer, uint amount);
   event Redemption(address indexed redeemer, address indexed issuer, uint amount);
   event Transfer(address indexed payer, address indexed recipient, address indexed issuer, uint amount);
   event InsufficientBalance(address indexed payer, address indexed recipient, uint amount, uint balance);
   event SelfIssuanceForbidden(address indexed blockedIssuer, uint amount);

   /*
    *  Public API
    */

   /* constant functions */

   function balance(address issuer) constant returns (uint balance) {
       return balances[msg.sender][issuer];
   }

   function float(address issuer) constant returns (uint float) {
       return floats[issuer];
   }

   /* nonconstant functions */

   function issue(address recipient, uint amount) returns (bool ok) {
       if (recipient != msg.sender) {
           _doIssue(recipient, amount);
           return true;
       } else {
           SelfIssuanceForbidden(recipient, amount);
           return false;
       }
   }

   function redeem(address issuer, uint amount) returns (bool ok) {
       if (!_sufficientBalance( issuer, issuer, amount ))
           return false;
       _redeem( issuer, amount );
       return true;
   }

   function transfer(address recipient, address issuer, uint amount) returns (bool ok) {
       if (!_sufficientBalance( recipient, issuer, amount ))
           return false;

       if (recipient == issuer) {
           _redeem( issuer, amount );
       } else if ( recipient == msg.sender ) {
           /* ignore -- transfers to oneself are no-ops */
       } else {
           _doTransfer( recipient, issuer, amount );
       }
   }

   /*
    *  Private Utilities
    */

   function _sufficientBalance(address recipient, address issuer, uint amount) private returns (bool ok){
       uint initialBalance = balances[msg.sender][issuer];

       if (initialBalance >= amount) {
           return true;
       } else {
           InsufficientBalance(msg.sender, recipient, amount, initialBalance);
           return false;
       }
   }

   // sufficient balance must already be guaranteed!
   function _redeem(address issuer, uint amount) private {
       balances[msg.sender][issuer] -= amount;
       floats[issuer] -= amount;

       Redemption(msg.sender, issuer, amount);
   }

   function _doIssue(address recipient, uint amount) private {
       balances[recipient][msg.sender] += amount;
       floats[msg.sender] += amount;

       Issuance( recipient, msg.sender, amount);
   }

   // sufficient balance must already be guaranteed!
   // must be verified that recipient != issuer (redemption)
   // transfers to sender should be blocked to prevent event generation
   function _doTransfer(address recipient, address issuer, uint amount) private {
       balances[msg.sender][issuer] -= amount;
       balances[recipient][issuer] += amount;

       Transfer( msg.sender, recipient, issuer, amount );
   }
}
