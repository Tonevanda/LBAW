<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    use HasFactory;

    protected $table = 'payment';

    public $timestamps = false;

    public $incrementing = false;

    protected $primaryKey = 'payment_type';

    protected $fillable = [
        'payment_type',
    ];

    public function scopeFilter($query, $payment_type)
    {

        $query->where('payment_type', '!=', $payment_type);

    }

}
