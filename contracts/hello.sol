// SPDX-License-Identifier: MIT
contract HelloWorld {
    string public message;

    constructor(string memory initialMessage) {
        message = initialMessage;
    }

    function updateMessage(string memory newMesssage) public {
        message = newMesssage;
    }
}