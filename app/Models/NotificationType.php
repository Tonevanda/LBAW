<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NotificationType extends Model
{
    use HasFactory;

    protected $table = 'notification';
    
    protected $fillable = ['notification_type', 'description'];

    protected $primaryKey = 'notification_type';

    public function notifications()
    {
        return $this->hasMany(Notification::class, 'notification_type');
    }
}
