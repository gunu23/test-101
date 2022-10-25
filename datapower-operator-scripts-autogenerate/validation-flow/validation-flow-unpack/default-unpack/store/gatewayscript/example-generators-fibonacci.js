/*
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2015,2016. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
*/

// the generator function for fibonacci sequence
function* fibonacci(){
  var n1 = 1, n2 = 1;
  while (true) {
    yield n1;       // yield back to the caller and return n1
    var temp = n1;
    n1 = n2;
    n2 += temp;
  }
}

// get the finonacci generator
var sequence = fibonacci();
var result = "Fibonacci sequence: ";

// calling next() to iterate on the generator
result = result + sequence.next().value;        // 1
result = result + ", " + sequence.next().value; // 1
result = result + ", " + sequence.next().value; // 2
result = result + ", " + sequence.next().value; // 3
result = result + ", " + sequence.next().value; // 5
result = result + ", " + sequence.next().value; // 8
result = result + ", " + sequence.next().value; // 13

session.output.write(result);
