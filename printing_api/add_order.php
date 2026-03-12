<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");

include "connection.php";

// Get the data sent from Flutter
$customer_name = $_POST['customer_name'];
$document_type = $_POST['document_type'];
$page_count = $_POST['page_count'];
$color_type = $_POST['color_type'];
$total_price = $_POST['total_price'];

// Insert it into the database
$sql = "INSERT INTO tbl_orders (customer_name, document_type, page_count, color_type, total_price, order_status) 
        VALUES (:customer_name, :document_type, :page_count, :color_type, :total_price, 'Pending')";

$stmt = $conn->prepare($sql);
$stmt->bindParam(":customer_name", $customer_name);
$stmt->bindParam(":document_type", $document_type);
$stmt->bindParam(":page_count", $page_count);
$stmt->bindParam(":color_type", $color_type);
$stmt->bindParam(":total_price", $total_price);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Order added successfully!"]);
} else {
    echo json_encode(["status" => "error", "message" => "Failed to add order."]);
}
?>