<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");

include "connection.php";

$order_id = $_POST['order_id'];
$order_status = $_POST['order_status'];

$sql = "UPDATE tbl_orders SET order_status = :order_status WHERE order_id = :order_id";
$stmt = $conn->prepare($sql);
$stmt->bindParam(":order_status", $order_status);
$stmt->bindParam(":order_id", $order_id);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Order status updated!"]);
} else {
    echo json_encode(["status" => "error", "message" => "Failed to update status."]);
}
?>