/*
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2016,2016. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
*/

var Fiber = require('fibers');

// Generator function. Returns a function which returns incrementing
// Fibonacci numbers with each call.
function Fibonacci() {
    // Create a new fiber which yields sequential Fibonacci numbers
    var fiber = Fiber(function() {
        fiber.yield(0); // F(0) -> 0
        var prev = 0, curr = 1;
        while (true) {
            fiber.yield(curr);
            var tmp = prev + curr;
            prev = curr;
            curr = tmp;
        }
    });
    // Return a bound handle to `run` on this fiber
    return fiber.run.bind(fiber);
}

// Initialize a new Fibonacci sequence and iterate up to 1597
var flow = "";
var seq = Fibonacci();
for (var ii = seq(); ii <= 1597; ii = seq()) {
    flow += ii;
}
session.output.write(flow);
