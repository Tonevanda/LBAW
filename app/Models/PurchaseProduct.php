<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class PurchaseProduct extends Model
{
    // Define the table associated with the model
    protected $table = 'purchase_product';

    // Define the primary key for the model
    protected $primaryKey = 'id';

    // Define the attributes that are mass assignable
    protected $fillable = [
        'purchase_id',
        'product_id',
        'price',
    ];

    // Define relationships
    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id');
    }
}
