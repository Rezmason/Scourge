
  
     class NME_assets_bite_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_biteicon1_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_biteicon2_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_biteicon3_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_forfeit_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_forfeit_button_base_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_knife_dr_gustavo__8081_hifi_mp3 extends flash.utils.ByteArray { }
  

  
     class NME_assets_library_xslt extends flash.utils.ByteArray { }
  

  
     class NME_assets_lion_roar_mp3 extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_license_txt extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_bold_eot extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_bold_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_bold_ttf extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_bold_woff extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_info_txt extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_light_eot extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_light_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_light_ttf extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_light_woff extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_promotion_png extends flash.display.BitmapData { public function new() { super(0,0); } }
  

  
     class NME_assets_miso_miso_eot extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_ttf extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_miso_woff extends flash.utils.ByteArray { }
  

  
     class NME_assets_miso_style_css extends flash.utils.ByteArray { }
  

  
     class NME_assets_mousepointer_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_omnomnom_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_rope_sna_michael__9004_hifi_mp3 extends flash.utils.ByteArray { }
  

  
     class NME_assets_rotate_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_scourgebitesymbols_fla extends flash.utils.ByteArray { }
  

  
     class NME_assets_scourgebitesymbols_html extends flash.utils.ByteArray { }
  

  
     class NME_assets_scourgebitesymbols_swf extends flash.utils.ByteArray { }
  

  
     class NME_assets_scourgelib_as extends flash.utils.ByteArray { }
  

  
     class NME_assets_scourgelib_swf extends flash.utils.ByteArray { }
  

  
     class NME_assets_scourgelib_swfml extends flash.utils.ByteArray { }
  

  
     class NME_assets_scourgelib_milled_swf extends flash.utils.ByteArray { }
  

  
     class NME_assets_skip_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_skip_button_base_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_swap_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_swap_button_base_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_well_button_base_svg extends flash.utils.ByteArray { }
  

  
     class NME_assets_well_button_template_ai extends flash.utils.ByteArray { }
  





class ApplicationMain
{
   static var mPreloader:NMEPreloader;

   public static function main()
   {
      var call_real = true;
      
         var loaded:Int = flash.Lib.current.loaderInfo.bytesLoaded;
         var total:Int = flash.Lib.current.loaderInfo.bytesTotal;
         if (loaded<total || true) /* Always wait for event */
         {
            call_real = false;
            mPreloader = new NMEPreloader();
            flash.Lib.current.addChild(mPreloader);
            mPreloader.onInit();
            mPreloader.onUpdate(loaded,total);
            flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, onEnter);
         }
      

      if (call_real)
         Scourge.main();
   }

   static function onEnter(_)
   {
      var loaded:Int = flash.Lib.current.loaderInfo.bytesLoaded;
      var total:Int = flash.Lib.current.loaderInfo.bytesTotal;
      mPreloader.onUpdate(loaded,total);
      if (loaded>=total)
      {
         mPreloader.onLoaded();
         flash.Lib.current.removeEventListener(flash.events.Event.ENTER_FRAME, onEnter);
         flash.Lib.current.removeChild(mPreloader);
         mPreloader = null;

         Scourge.main();
      }
   }

   public static function getAsset(inName:String) : Dynamic
   {
      
      if (inName=="assets/bite.svg")
         return new NME_assets_bite_svg();
      
      if (inName=="assets/biteicon1.svg")
         return new NME_assets_biteicon1_svg();
      
      if (inName=="assets/biteicon2.svg")
         return new NME_assets_biteicon2_svg();
      
      if (inName=="assets/biteicon3.svg")
         return new NME_assets_biteicon3_svg();
      
      if (inName=="assets/forfeit.svg")
         return new NME_assets_forfeit_svg();
      
      if (inName=="assets/forfeit_button_base.svg")
         return new NME_assets_forfeit_button_base_svg();
      
      if (inName=="assets/knife_dr-Gustavo_-8081_hifi.mp3")
         return new NME_assets_knife_dr_gustavo__8081_hifi_mp3();
      
      if (inName=="assets/library.xslt")
         return new NME_assets_library_xslt();
      
      if (inName=="assets/lion_roar.mp3")
         return new NME_assets_lion_roar_mp3();
      
      if (inName=="assets/miso/Miso License.txt")
         return new NME_assets_miso_miso_license_txt();
      
      if (inName=="assets/miso/miso-bold.eot")
         return new NME_assets_miso_miso_bold_eot();
      
      if (inName=="assets/miso/miso-bold.svg")
         return new NME_assets_miso_miso_bold_svg();
      
      if (inName=="assets/miso/miso-bold.ttf")
         return new NME_assets_miso_miso_bold_ttf();
      
      if (inName=="assets/miso/miso-bold.woff")
         return new NME_assets_miso_miso_bold_woff();
      
      if (inName=="assets/miso/MISO-info.txt")
         return new NME_assets_miso_miso_info_txt();
      
      if (inName=="assets/miso/miso-light.eot")
         return new NME_assets_miso_miso_light_eot();
      
      if (inName=="assets/miso/miso-light.svg")
         return new NME_assets_miso_miso_light_svg();
      
      if (inName=="assets/miso/miso-light.ttf")
         return new NME_assets_miso_miso_light_ttf();
      
      if (inName=="assets/miso/miso-light.woff")
         return new NME_assets_miso_miso_light_woff();
      
      if (inName=="assets/miso/miso-promotion.png")
         return new NME_assets_miso_miso_promotion_png();
      
      if (inName=="assets/miso/miso.eot")
         return new NME_assets_miso_miso_eot();
      
      if (inName=="assets/miso/miso.svg")
         return new NME_assets_miso_miso_svg();
      
      if (inName=="assets/miso/miso.ttf")
         return new NME_assets_miso_miso_ttf();
      
      if (inName=="assets/miso/miso.woff")
         return new NME_assets_miso_miso_woff();
      
      if (inName=="assets/miso/style.css")
         return new NME_assets_miso_style_css();
      
      if (inName=="assets/mousepointer.svg")
         return new NME_assets_mousepointer_svg();
      
      if (inName=="assets/omnomnom.svg")
         return new NME_assets_omnomnom_svg();
      
      if (inName=="assets/rope_sna-Michael_-9004_hifi.mp3")
         return new NME_assets_rope_sna_michael__9004_hifi_mp3();
      
      if (inName=="assets/rotate.svg")
         return new NME_assets_rotate_svg();
      
      if (inName=="assets/ScourgeBiteSymbols.fla")
         return new NME_assets_scourgebitesymbols_fla();
      
      if (inName=="assets/ScourgeBiteSymbols.html")
         return new NME_assets_scourgebitesymbols_html();
      
      if (inName=="assets/ScourgeBiteSymbols.swf")
         return new NME_assets_scourgebitesymbols_swf();
      
      if (inName=="assets/ScourgeLib.as")
         return new NME_assets_scourgelib_as();
      
      if (inName=="assets/ScourgeLib.swf")
         return new NME_assets_scourgelib_swf();
      
      if (inName=="assets/ScourgeLib.swfml")
         return new NME_assets_scourgelib_swfml();
      
      if (inName=="assets/ScourgeLib_milled.swf")
         return new NME_assets_scourgelib_milled_swf();
      
      if (inName=="assets/skip.svg")
         return new NME_assets_skip_svg();
      
      if (inName=="assets/skip_button_base.svg")
         return new NME_assets_skip_button_base_svg();
      
      if (inName=="assets/swap.svg")
         return new NME_assets_swap_svg();
      
      if (inName=="assets/swap_button_base.svg")
         return new NME_assets_swap_button_base_svg();
      
      if (inName=="assets/well_button_base.svg")
         return new NME_assets_well_button_base_svg();
      
      if (inName=="assets/well_button_template.ai")
         return new NME_assets_well_button_template_ai();
      

      return null;
   }
}
