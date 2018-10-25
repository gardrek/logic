extern crate logwi;
use logwi::value::Value;
use logwi::{Board, Component};

fn test_print(v: &Value) {
    println!("{0}   {0:?}", v);
}

fn main() {
    let _mainboard = Board::new();

    let v = Value::new();
    v.test();

    let v = vec![
        Value::from(-1.0),
        Value::from(1.0 / 3.0 - 0.33333),
        Value::new(),
        Value::from(-0.0),
        Value::from(0.25),
        Value::from(1.0 / 3.0),
    ];

    for n in &v {
        test_print(n)
    }
    println!();

    println!("{}", v.iter().fold(Value::new(), |sum, x| sum.clone() + x.clone()));
    println!();

    println!();

    let a = Value::from(0.25);
    let b = Value::from(1.0 / 3.0);
    let c = a.clone() + b.clone();

    test_print(&a);
    test_print(&b);
    test_print(&c);

    let c = a == Value::from(0.25);
    println!("{}", c);

    let v = Value::from(2.0);
    test_print(&v);


    //println!("{:?}", v);
    //let v:f64 = Value::from(0.0).into();
    //println!("{:?}", v);
    //let v:f64 = Value::from(1.0).into();
    //println!("{:?}", v);
    //let v:f64 = Value::from(0.874442799).into();
    //println!("{:?}", v);

    //let v:f64 = Value::from(0.6180339887).into();
    //println!("{:?}", v);
    //println!("{:?}", 1.0 / v);

    //let v:f64 = Value::from(2.1).into();
    //println!("{:?}", v);
    //println!("{:?}", Value::from(52.1));
    //println!("{:?}", Value::from(1.0));
}
