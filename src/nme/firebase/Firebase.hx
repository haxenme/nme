package nme.firebase;

#if !firebase
#error "Please haxedef firebase in your project"
#end

class Firebase
{
   public static inline var ADD_PAYMENT_INFO = "add_payment_info";
   public static inline var ADD_TO_CART = "add_to_cart";
   public static inline var ADD_TO_WISHLIST = "add_to_wishlist";
   public static inline var APP_OPEN = "app_open";
   public static inline var BEGIN_CHECKOUT = "begin_checkout";
   public static inline var ECOMMERCE_PURCHASE = "ecommerce_purchase";
   public static inline var GENERATE_LEAD = "generate_lead";
   public static inline var JOIN_GROUP = "join_group";
   public static inline var LEVEL_UP = "level_up";
   public static inline var LOGIN = "login";
   public static inline var POST_SCORE = "post_score";
   public static inline var PRESENT_OFFER = "present_offer";
   public static inline var PURCHASE_REFUND = "purchase_refund";
   public static inline var SEARCH = "search";
   public static inline var SELECT_CONTENT = "select_content";
   public static inline var SHARE = "share";
   public static inline var SIGN_UP = "sign_up";
   public static inline var SPEND_VIRTUAL_CURRENCY = "spend_virtual_currency";
   public static inline var TUTORIAL_BEGIN = "tutorial_begin";
   public static inline var TUTORIAL_COMPLETE = "tutorial_complete";
   public static inline var UNLOCK_ACHIEVEMENT = "unlock_achievement";
   public static inline var VIEW_ITEM = "view_item";
   public static inline var VIEW_ITEM_LIST = "view_item_list";
   public static inline var VIEW_SEARCH_RESULTS = "view_search_results";
   public static inline var EARN_VIRTUAL_CURRENCY = "earn_virtual_currency";


   // Params ...
   public static inline var ACHIEVEMENT_ID = "achievement_id";
   public static inline var CHARACTER = "character";
   public static inline var TRAVEL_CLASS = "travel_class";
   public static inline var CONTENT_TYPE = "content_type";
   public static inline var CURRENCY = "currency";
   public static inline var COUPON = "coupon";
   public static inline var START_DATE = "start_date";
   public static inline var END_DATE = "end_date";
   public static inline var FLIGHT_NUMBER = "flight_number";
   public static inline var GROUP_ID = "group_id";
   public static inline var ITEM_CATEGORY = "item_category";
   public static inline var ITEM_ID = "item_id";
   public static inline var ITEM_LOCATION_ID = "item_location_id";
   public static inline var ITEM_NAME = "item_name";
   public static inline var LOCATION = "location";
   public static inline var LEVEL = "level";
   public static inline var SIGN_UP_METHOD = "sign_up_method";
   public static inline var NUMBER_OF_NIGHTS = "number_of_nights";
   public static inline var NUMBER_OF_PASSENGERS = "number_of_passengers";
   public static inline var NUMBER_OF_ROOMS = "number_of_rooms";
   public static inline var DESTINATION = "destination";
   public static inline var ORIGIN = "origin";
   public static inline var PRICE = "price";
   public static inline var QUANTITY = "quantity";
   public static inline var SCORE = "score";
   public static inline var SHIPPING = "shipping";
   public static inline var TRANSACTION_ID = "transaction_id";
   public static inline var SEARCH_TERM = "search_term";
   public static inline var TAX = "tax";
   public static inline var VALUE = "value";
   public static inline var VIRTUAL_CURRENCY_NAME = "virtual_currency_name";


   public static var optOut = false;


   public static function logEvent(eventName:String, ?params:{ } )
   {
      if (optOut)
         return;

      #if android
      var strNames:Array<String> = null;
      var strVals:Array<String> = null;
      var dblNames:Array<String> = null;
      var dblVals:Array<Float> = null;
      var intNames:Array<String> = null;
      var intVals:Array<Int> = null;

      if (params!=null)
      {
         for(f in Reflect.fields(params))
         {
            var val:Dynamic = Reflect.field(params, f);
            if (Std.is(val,Int))
            {
               if (intNames==null)
               {
                   intNames = [f];
                   intVals = [ Std.int(val) ];
               }
               else
               {
                   intNames.push(f);
                   intVals.push(Std.int(val));
               }
            }
            else if (Std.is(val,Float))
            {
               if (dblNames==null)
               {
                   dblNames = [f];
                   dblVals = [ cast val ];
               }
               else
               {
                   dblNames.push(f);
                   dblVals.push( cast val);
               }
            }
            else
            {
               if (strNames==null)
               {
                   strNames = [f];
                   strVals = [ Std.string(val) ];
               }
               else
               {
                   strNames.push(f);
                   strVals.push(Std.string(val));
               }
            }
         }
      }

      firebaseLog(eventName, strNames, strVals, intNames, intVals, dblNames, dblVals);
      #end
   }

   public static function levelUp(level:Int, ?character:String)
   {
      var params:Dynamic = { level:level };
      if (character!=null)
         params.character = character;
      logEvent(LEVEL_UP,params);
   }

   public static function postScore(score:Int, ?level:Int, ?character:String)
   {
      var params:Dynamic = { score:score };
      if (level!=null)
         params.level = level;
      if (character!=null)
         params.character = character;
      logEvent(POST_SCORE,params);
   }

   public static function appOpen()
   {
      logEvent( APP_OPEN );
   }

   public static function levelStart(levelId:Int)
   {
      logEvent( "level_start", { level_name:levelId } );
   }

   public static function levelEnd(levelId:Int, ?success:String)
   {
      var params:Dynamic = { level_name:levelId };
      if (success!=null)
         params.success = success;
      logEvent( "level_end", params );
   }


   public static function tutorialBegin()
   {
      logEvent( TUTORIAL_BEGIN );
   }

   public static function tutorialComplete()
   {
      logEvent( TUTORIAL_COMPLETE );
   }


   #if android
   static var firebaseLog = JNI.createStaticMethod("org/haxe/nme/GameActivity", "firebaseLog", "(Ljava/lang/String;[Ljava/lang/String;[Ljava/lang/String;[Ljava/lang/String;[I[Ljava/lang/String;[D)V");
   #end
}

