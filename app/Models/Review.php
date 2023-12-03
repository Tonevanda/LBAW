<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    use HasFactory;

    protected $table = 'review';

    public $timestamps = false;

    protected $primaryKey = 'id';

    protected $fillable = [
        'id',
        'user_id',
        'product_id',
        'title',
        'description',
        'rating',
        'date',
    ];

    public function getAuthor()
    {
        return $this->belongsTo(Authenticated::class, 'user_id');
    }


    public function products()
    {
        return $this->belongsTo(Product::class, 'product_id');
    }
}
