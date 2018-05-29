extern crate logwi;
use logwi::Value;

fn main() {
    let v:f64 = Value::from(-1.0).into();
    println!("{:?}", v);
    let v:f64 = Value::from(0.0).into();
    println!("{:?}", v);
    let v:f64 = Value::from(1.0).into();
    println!("{:?}", v);
    let v:f64 = Value::from(0.874442799).into();
    println!("{:?}", v);

    let v:f64 = Value::from(0.6180339887).into();
    println!("{:?}", v);
    println!("{:?}", 1.0 / v);

    let v:f64 = Value::from(2.1).into();
    println!("{:?}", v);
    println!("{:?}", Value::from(52.1));
    println!("{:?}", Value::from(1.0));
}
