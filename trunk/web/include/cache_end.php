<?php
 //cache foot start      
                if(isset($cache_file)){
                        if(  $OJ_MEMCACHE  ||  $OJ_APCU_OK  ){
                                if( $OJ_APCU_OK )
                                        apcu_store($cache_file,ob_get_contents(),$cache_time);
                                else
                                        $mem->set($cache_file,ob_get_contents(),0,$cache_time);
                        }else{
                          // if(!file_exists("cache")) mkdir("cache");
                          //      file_put_contents($file,ob_get_contents());
                        }
                }
        //cache foot stop
?>
<!--not cached-->
