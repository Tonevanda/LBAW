<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Authenticated extends Model
{
    use HasFactory;

    protected $table = 'authenticated';

    public $timestamps = false;

    protected $primaryKey = 'user_id';

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function showAllProducts()
    {
        return $this->belongsToMany(Product::class, 'shopping_cart');
    }
}
