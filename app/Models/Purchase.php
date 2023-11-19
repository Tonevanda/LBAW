<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Purchase extends Model
{
    use HasFactory;

    protected $table = 'purchase';

    public $timestamps = false;

    protected $primaryKey = 'id';

    protected $fillable = [
        'id',
        'user_id',
        'price',
        'quantity',
        'payment_type',
        'destination',
        'stage_state',
        'isTracked',
        'orderedat',
        'orderarrivedat',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function Products()
    {
        return $this->belongsToMany(Product::class, 'purchase_product', 'purchase_id', 'product_id');
    }


}
