# Description

Short version: the file type doesn’t always tell you the core, especially for arcade  
 ROMs.

 Easy rule

 -  .sfc, .smc → SNES core like snes9x

 - .nes → NES core                                                                     

- .gba → mGBA                                                                         

- .bin/.cue, .chd → depends on system                                                 

- arcade .zip → usually FBNeo or MAME 

 ### Method 1: check the extension                                                     
                                                                                       
 Common mappings:                                                                      
                                                                                       
 - .sfc / .smc → SNES → snes9x                                                         
 - .gb → Game Boy → gambatte / mgba                                                    
 - .gbc → Game Boy Color → gambatte / sameboy                                          
 - .gba → Game Boy Advance → mgba                                                      
 - .md / .gen / .bin → Sega Genesis → genesis_plus_gx                                  
 - .cue / .chd → PlayStation / Sega CD / PC Engine CD etc. → depends on game           
 - .n64 / .z64 / .v64 → Nintendo 64 → mupen64plus-next                                 
 - .zip → could be arcade, could be compressed console ROM, so not enough by itself 


 ### Method 3: let RetroArch suggest one                                               
                                                                                       
 In the GUI:                                                                           
 1. Open RetroArch                                                                     
 2. Load Content                                                                       
 3. Select the file                                                                    
 4. RetroArch may show associated cores                                                
                                                                                       
 This is helpful, but for arcade zips it still may not guarantee the ROM matches that  
 core.                                                                                 
                                                                                       
 ────────────────────────────────────────────────────────────────────────────────      
                                                                                       
 ### Method 4: inspect installed cores                                                 
                                                                                       
 On your system, you already have these relevant cores:                                
 - /usr/lib/libretro/snes9x_libretro.so                                                
 - /usr/lib/libretro/fbneo_libretro.so                                                 
 - /usr/lib/libretro/mame_libretro.so                                                  
                                                                                       
 So:                                                                                   
 - SNES game → snes9x                                                                  
 - Arcade game → fbneo or mame 


 If you want, I can give you a small cheat sheet like:                                 
                                                                                       
 - SNES → this core                                                                    
 - Genesis → this core                                                                 
 - GBA → this core                                                                     
 - Arcade → this core first                                                            
                                                                                       
 for your Linux RetroArch setup.

## how to execute on terminal  

```
retroarch -L /usr/lib/libretro/snes9x_libretro.so  Bugs\ Bunny\ -\ Rabbit\ Rampage\ \(USA\).sfc
```





 ```bash                                                                               
   retroarch -L /usr/lib/libretro/fbneo_libretro.so "/home/pazthor/Downloads/dino.zip" 
 ```

If not:                                                                               
                                                                                       
 ```bash                                                                               
   retroarch -L /usr/lib/libretro/mame_libretro.so "/home/pazthor/Downloads/dino.zip"  
 ```



