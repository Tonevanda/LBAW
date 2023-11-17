<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'description', 'price'];

    protected $table = 'product';

    public $timestamps = false;

    protected $primaryKey = 'id';

    public function showAllBuyers()
    {
        return $this->belongsToMany(Authenticated::class, 'shopping_cart');
    }
}
