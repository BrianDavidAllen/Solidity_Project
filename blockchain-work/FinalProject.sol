pragma solidity ^0.4.24;

import "./SafeMath.sol";

contract Store{

    struct Item{
        string name;
        uint256 cost;
        uint32 count;
        bool exsists; 
    }
    
    struct OrderedItems{
        string name;
        uint256 cost;
        uint32 count;
        address customerAddr;
    }
    
    struct CartItem{
        string name;
        uint32 count;
        uint256 price;
    }

    //This won't work
    struct Order {
        uint32 orderNo;
        uint32 itemCount;
        Item[10] orderItems;
    }
    
    using SafeMath for uint256;
    using SafeMath for uint32;
    
    address private owner;
    mapping(address => bool) internal employees;
    
    string public welcome = "Welcome to our store! Please note all prices are in Sazbo. Shopping cart size is 10 items";
    
    //variables for mataining stock. StockNumber mapping is for displaying stock on frontend.
    mapping(string => Item) internal stock;
    mapping(uint32 => Item) internal numberToItem;
    uint32 internal numberItems;
   
    //keeping track of customers shoppingCart
    mapping(address => CartItem[10]) shoppingCart;
    mapping(address => uint8) itemsInCart;
   
    //Keeping track of orders and the shipment of orders
    mapping(uint32 => OrderedItems) orders;
    uint32 private orderNumber; 
    mapping(uint32 => bool) shipped;
    mapping(address => uint32[]) customerOrders;
    
    //Using for temp variable inside buy functions. Need a mutex so bad.
    OrderedItems currentOrder;
    
    constructor() public{
        owner = msg.sender;
        employees[msg.sender] = true;
    }
    
    modifier onlyEmployees (){
        require(employees[msg.sender]);
        _;
    }
    
    modifier onlyOnwer(){
        require(msg.sender == owner);
        _;
    }
    
    function welcome () public view returns (string){
        return welcome;
    }
    
    function setWelcome(string message) public onlyOnwer{
        welcome = message;
    }
    
    function storeBalance() public view onlyOnwer returns (uint256) {
        return address(this).balance;
    }
    
    function getPaid() public onlyOnwer{
        owner.transfer(address(this).balance);
    }
    
    //authorize employee for contract use
    function addEmployee (address employee) public onlyOnwer{
        employees[employee] = true;
    }
    
    //remove employee from contract use
    function removeEmployee (address employee) public onlyOnwer{
        employees[employee] = false;
    }
    
    //change store ownershp
    function transferOwnership (address newOwner) public onlyOnwer {
        employees[owner] = false;
        owner = newOwner;
        employees[newOwner] = true;
    }
    
    //add item to store stock
    function addItem (string name, uint256 cost, uint32 count) external onlyEmployees{
        require(!stock[name].exsists);
        stock[name] = Item(name, cost, count, true);
        numberItems += 1;
        numberToItem[numberItems] = Item(name, cost, count, true);
    }
    
    //retuns stock of item along with its cost
    function viewItems (string name) public view returns (string itemName, uint256 cost, uint32 count){
        return (stock[name].name, stock[name].cost, stock[name].count);
    }
    
    //returns number of differnt items in the store
    function getTypesNumber () public view onlyEmployees returns (uint32){
        return numberItems;
    }
    
    //returns item info mapped to item number
    function getStockByNumber (uint32 itemNo) public view onlyEmployees returns (string itemName, uint256 cost, uint32 count){
        return (numberToItem[itemNo].name, numberToItem[itemNo].cost, numberToItem[itemNo].count);
    }
    
    //increases items stock
    function incrementStock(string name, uint32 amount) external onlyEmployees{
        require(stock[name].exsists);
        require(stock[name].count + amount > stock[name].count);
        stock[name].count += amount;
    }
    
    //remove items from stock
    function removeStock(string name, uint32 amount) internal {
        //check for underflow 
        require(stock[name].count - amount < stock[name].count, "We currently don't have that many items");
        
        //remove amount of items from inventory 
        stock[name].count -= amount;
        if(stock[name].count == 0){
            stock[name].exsists = false;
        }
    }
    
    function addToCart(string name, uint32 amount) external{
        //check to see amount of items is avaible 
        //check to see that the user's cart isn't full
        //check for cost overflow
        require(stock[name].count >= amount);
        require(itemsInCart[msg.sender] < 10);
        require(amount * stock[name].cost > stock[name].cost);
        
        //add item to shoppingCart
        shoppingCart[msg.sender][itemsInCart[msg.sender]] = CartItem(name, amount, amount * stock[name].cost);
        itemsInCart[msg.sender] += 1;
    }
    
    //returns customers shpping cart. Could change a function that returns singles to remove experimental ABIEncoderV2
    function getCartItems (address addr, uint32 index) external view onlyEmployees returns (string names, uint32 quanity, uint256 price){
        return(shoppingCart[addr][index].name, shoppingCart[addr][index].count, shoppingCart[addr][index].price);
    }
    
    //returns number of items in customer's cart
    function getCartNumber (address addr) external view onlyEmployees returns(uint32){
        return itemsInCart[addr];
    }
    
    //returns 
    function getCartCost(address addr) external view returns (uint256 price){
        //Not sure why this needs to be done.
        uint[] memory cartTotal = new uint[](1);
        
        //Check inventory and generate total
        for(uint i = 0; i < itemsInCart[addr]; i++){
            //requre that we have the stock. Ideally checked infront in also
            require(shoppingCart[addr][i].count <= stock[shoppingCart[addr][i].name].count, "We currently don't have the stock");
            cartTotal[0] += shoppingCart[addr][i].price * 1 szabo;
        }
        
        return cartTotal[0];
    } 
 
    function purchaseCart() external payable{
        //Not sure why this needs to be done.
        uint[] memory total = new uint[](1);
        //Check inventory and generate total
        for(uint i = 0; i < itemsInCart[msg.sender]; i++){
            //requre that we have the stock. Ideally checked infront in also
            require(shoppingCart[msg.sender][i].count <= stock[shoppingCart[msg.sender][i].name].count, "We currently don't have the stock");
            createOrder(shoppingCart[msg.sender][i].name, shoppingCart[msg.sender][i].count);
            total[0] += shoppingCart[msg.sender][i].price * 1 szabo;
        }
        
        require(msg.value > total[0], "Sorry, you didn't send enough ether");
        
        //instead of zeroing out shopping cart just sent items to zero. Cost less gas.
        itemsInCart[msg.sender] = 0;
        
        //return overpayment if any
        uint256 overpayment;
        if(total[0] < msg.value){    
            overpayment = msg.value.sub((total[0]));
            msg.sender.transfer(overpayment);
        }
    }
    
    function buyNow(string name, uint32 amount) public payable{
        //Check that we have stock
        //Check for overflow
        //make sure enough ether was sent
        require(stock[name].count >= amount);
        require(amount * stock[name].cost > stock[name].cost);
        require(msg.value >= (stock[name].cost * amount) * 1 szabo);


        //Increase orderNumber and create order
        //link customer address to order number along with items
        createOrder(name, amount);
        
        //return overpayment if any
        uint256 overpayment;
        if((stock[name].cost * amount) * 1 szabo < msg.value){    
            overpayment = msg.value.sub((stock[name].cost * amount) * 1 szabo);
            msg.sender.transfer(overpayment);
        }
    }
    
    //returns order info for given order number
    function getOrderInfo(uint32 orderNo) public view onlyEmployees returns(string name, uint256 cost, uint32 count, address addr) {
        return (orders[orderNo].name, orders[orderNo].cost, orders[orderNo].count, orders[orderNo].customerAddr);
    }
    
    //returns array of customer's order numbers
    function getCustomerOrders (address addr)public view onlyEmployees returns (uint32[]){
        return customerOrders[addr];
    }
    
    //set an order to shipped
    function setOrderShipped (uint32 order) external onlyEmployees {
        shipped[order] = true;
    }
    
    //function to create new order
    function createOrder(string name, uint32 amount) internal {
        removeStock(name, amount);
        
        if(stock[name].count == 0){
            stock[name].exsists = false;
        }
        
        //Increase orderNumber and create order
        //link customer address to order number along with items
        orderNumber += 1;
        currentOrder = OrderedItems(stock[name].name, stock[name].cost, amount, msg.sender);
        orders[orderNumber] = currentOrder;
        customerOrders[msg.sender].push(orderNumber);
    }
}