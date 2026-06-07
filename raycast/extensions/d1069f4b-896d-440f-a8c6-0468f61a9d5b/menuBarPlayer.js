"use strict";var E=Object.create;var u=Object.defineProperty;var U=Object.getOwnPropertyDescriptor;var L=Object.getOwnPropertyNames;var M=Object.getPrototypeOf,W=Object.prototype.hasOwnProperty;var C=(t,n)=>{for(var e in n)u(t,e,{get:n[e],enumerable:!0})},h=(t,n,e,a)=>{if(n&&typeof n=="object"||typeof n=="function")for(let i of L(n))!W.call(t,i)&&i!==e&&u(t,i,{get:()=>n[i],enumerable:!(a=U(n,i))||a.enumerable});return t};var $=(t,n,e)=>(e=t!=null?E(M(t)):{},h(n||!t||!t.__esModule?u(e,"default",{value:t,enumerable:!0}):e,t)),F=t=>h(u({},"__esModule",{value:!0}),t);var q={};C(q,{default:()=>N});module.exports=F(q);var c=require("react");var k=$(require("node:process"),1),x=require("node:util"),S=require("node:child_process"),O=(0,x.promisify)(S.execFile);async function l(t,{humanReadableOutput:n=!0}={}){if(k.default.platform!=="darwin")throw new Error("macOS only");let e=n?[]:["-ss"],{stdout:a}=await O("osascript",["-e",t,e]);return a.trim()}var r=require("@raycast/api");var s=require("@raycast/api");function f(t){return`
    tell application "Spotify"
      if not application "Spotify" is running then
        activate

        set _maxOpenWaitTimeInSeconds to 5
        set _openCounter to 1
        repeat until application "Spotify" is running
          delay 1
          set _openCounter to _openCounter + 1
          if _openCounter > _maxOpenWaitTimeInSeconds then exit repeat
        end repeat
      end if
      ${t}
    end tell`}async function m(t){if(await(0,s.closeMainWindow)({clearRootSearch:!0}),!(await(0,s.getApplications)()).some(a=>a.name==="Spotify")){await(0,s.showHUD)("Spotify is not installed");return}await l(t)}var o=require("react/jsx-runtime");function R(t){let[n,e,a,i]=t.split("||").map(d=>d.trim());return{artworkUrl:n||void 0,track:e||void 0,artist:a||void 0,state:i==="playing"||i==="paused"||i==="stopped"?i:"unknown"}}async function v(){let n=await l(`
    if application "Spotify" is not running then
      return "||||||stopped"
    end if

    property _artworkUrl : ""
    property _trackName : ""
    property _artistName : ""
    property _playerState : "unknown"

    tell application "Spotify"
      try
        set _playerState to player state as string
        set _trackName to name of current track
        set _artistName to artist of current track
        set _artworkUrl to artwork url of current track
      end try
    end tell

    return _artworkUrl & "||" & _trackName & "||" & _artistName & "||" & _playerState
  `);return R(n)}function z(t){return!!t&&(t.startsWith("https://")||t.startsWith("http://"))}function H(t){if(t)return t.replace(/\s*[-–—]\s*remaster(?:ed)?(?:\s*\d{4})?$/i,"").replace(/\s*\((?:[^)]*version|[^)]*remaster(?:ed)?[^)]*)\)$/i,"").replace(/\s*\[(?:[^\]]*version|[^\]]*remaster(?:ed)?[^\]]*)\]$/i,"").replace(/\s+/g," ").trim()}function P(t,n){return t.length<=n?t:n<=1?"\u2026":`${t.slice(0,n-1)}\u2026`}function D(t,n){let e=n.cleanupSongTitle?H(t.track):t.track;if(!(!t.artist&&!e))return!t.artist||n.hideArtistName?e?P(e,n.nowPlayingTextLength):void 0:e?P(`${e} by ${t.artist}`,n.nowPlayingTextLength):`Song by ${t.artist}`}function V(t,n){let e=t.state!=="playing";if(!(n.hideIconWhenIdle&&e))return n.menuBarIcon==="music"?r.Icon.Music:n.menuBarIcon==="artwork"&&z(t.artworkUrl)?t.artworkUrl:"icon.png"}function N(){let{showTextInMenuBar:t,hideArtistName:n,cleanupSongTitle:e,hideIconWhenIdle:a,nowPlayingTextLength:i,menuBarIcon:I}=(0,r.getPreferenceValues)(),[d,A]=(0,c.useState)(!0),[p,T]=(0,c.useState)({state:"unknown"});(0,c.useEffect)(()=>{let w=!0;return v().then(B=>{w&&T(B)}).then(()=>{w&&A(!1)}),()=>{w=!1}},[]);let g=Number.parseInt(i??"30",10),_=Number.isFinite(g)&&g>0?g:30,b=V(p,{menuBarIcon:I??"spotify",hideIconWhenIdle:a}),y=D(p,{hideArtistName:n,cleanupSongTitle:e,nowPlayingTextLength:_});return(0,o.jsxs)(r.MenuBarExtra,{icon:b,isLoading:d,title:t?y:void 0,children:[(0,o.jsx)(r.MenuBarExtra.Section,{children:(0,o.jsx)(r.MenuBarExtra.Item,{title:y||"Not playing"})}),(0,o.jsxs)(r.MenuBarExtra.Section,{children:[(0,o.jsx)(r.MenuBarExtra.Item,{title:p.state==="playing"?"Pause":"Play",onAction:async()=>{await m(f("playpause"))},icon:p.state==="playing"?r.Icon.Pause:r.Icon.Play}),(0,o.jsx)(r.MenuBarExtra.Item,{title:"Next",icon:r.Icon.Forward,onAction:async()=>{await m(f("next track"))}}),(0,o.jsx)(r.MenuBarExtra.Item,{title:"Previous",icon:r.Icon.Rewind,onAction:async()=>{await m(f("previous track"))}})]}),(0,o.jsx)(r.MenuBarExtra.Section,{children:(0,o.jsx)(r.MenuBarExtra.Item,{title:"Configure Command",onAction:r.openCommandPreferences})})]})}
