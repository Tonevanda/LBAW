<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class ProductStatistic extends Model
{
    protected $table = 'product_statistic';
    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id');
    }

}
