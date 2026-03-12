<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");

include "connection.php";

$order_id = $_POST['order_id'];

$sql = "DELETE FROM tbl_orders WHERE order_id = :order_id";
$stmt = $conn->prepare($sql);
$stmt->bindParam(":order_id", $order_id);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Order deleted successfully!"]);
} else {
    echo json_encode(["status" => "error", "message" => "Failed to delete order."]);
}
?>