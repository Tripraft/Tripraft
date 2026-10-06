// Purpose: Regression tests for auth Service, including success and failure behavior.
jest.mock('../config/globalConfig',()=>({__esModule:true,default:{API_BASE_URL:'http://localhost/api',ENDPOINTS:{AUTH:'/v1/auth'},STORAGE_KEYS:{ACCESS_TOKEN:'accessToken',REFRESH_TOKEN:'refreshToken',CURRENT_USER:'currentUser'}}}));
import auth from '../services/sqlAuthService';
const response=(status,data)=>({ok:status<400,status,json:async()=>data});
beforeEach(()=>{localStorage.clear();auth._clearAuth();auth._isRefreshing=false;auth._refreshPromise=null;auth._initializationPromise=null;auth.authStateListeners=[];global.fetch=jest.fn();document.cookie='csrf_token=csrf; path=/';});
it('refreshes with only cookies when there is no readable access token',async()=>{
 fetch.mockResolvedValue(response(200,{success:true,data:{}}));await expect(auth.refreshAccessToken()).resolves.toMatchObject({success:true});
 expect(fetch.mock.calls[0][1]).toMatchObject({credentials:'include',headers:{'X-CSRF-Token':'csrf'},body:'{}'});
 expect(await auth.getIdToken()).toBeNull();expect(auth.accessToken).toBe('__cookie__');
});
it('shares a single refresh request across concurrent callers',async()=>{
 let resolve;fetch.mockReturnValue(new Promise(r=>{resolve=r;}));const a=auth.refreshAccessToken();const b=auth.refreshAccessToken();
 resolve(response(200,{data:{}}));await Promise.all([a,b]);expect(fetch).toHaveBeenCalledTimes(1);
});
it.each([500,503])('keeps the session after refresh status %s',async status=>{
 auth._saveAuth(null,null,{id:'uuid'});fetch.mockResolvedValue(response(status,{}));await auth.refreshAccessToken();expect(auth.currentUser).toEqual({id:'uuid'});
});
it('keeps the session after transient network failure',async()=>{
 auth._saveAuth(null,null,{id:'uuid'});fetch.mockRejectedValue(new Error('Offline'));await auth.refreshAccessToken();expect(auth.currentUser.id).toBe('uuid');
});
it.each([401])('clears a rejected session on refresh status %s',async status=>{
 auth._saveAuth(null,null,{id:'uuid'});fetch.mockResolvedValue(response(status,{}));await auth.refreshAccessToken();expect(auth.currentUser).toBeNull();expect(localStorage.getItem('currentUser')).toBeNull();
});
it('keeps a device session when refresh is rejected by CSRF protection', async () => {
 auth._saveAuth(null,null,{id:'uuid'});
 fetch.mockResolvedValue(response(403,{error:{message:'CSRF token missing'}}));
 await expect(auth.refreshAccessToken()).resolves.toMatchObject({success:false,message:'CSRF token missing'});
 expect(auth.currentUser.id).toBe('uuid');
});
it('clears authentication even when a rejection contains HTML instead of JSON',async()=>{
 auth._saveAuth(null,null,{id:'uuid'});fetch.mockResolvedValue({ok:false,status:401,json:async()=>{throw new SyntaxError('HTML');}});await auth.refreshAccessToken();expect(auth.currentUser).toBeNull();
});
it('sends CSRF on logout and keeps tokens out of local storage',async()=>{
 auth._saveAuth(null,null,{id:'uuid'});expect(localStorage.getItem('accessToken')).toBeNull();expect(localStorage.getItem('refreshToken')).toBeNull();fetch.mockResolvedValue(response(200,{}));await auth.signOut();expect(fetch.mock.calls[0][1].headers['X-CSRF-Token']).toBe('csrf');
});
it('uses server administrator and verification fields without inventing verification',()=>{
 const user=auth._createUserObject({id:'0190-uuid',email:'test@example.com',is_admin:true},null);expect(user.uid).toBe('0190-uuid');expect(user.is_admin).toBe(true);expect(user.emailVerified).toBe(false);
});
it('normalizes login email before sending it to the backend',async()=>{
 fetch.mockResolvedValue(response(200,{data:{user:{id:'uuid',email:'person@example.com'}}}));
 await expect(auth.signInWithEmail('  PERSON@EXAMPLE.COM  ','password')).resolves.toMatchObject({success:true});
 expect(JSON.parse(fetch.mock.calls[0][1].body)).toEqual({email:'person@example.com',password:'password'});
});

it.each(['signInWithEmail', 'signUpWithEmail'])('displays structured server errors from %s as text', async method => {
 fetch.mockResolvedValue(response(401,{error:{code:'AUTH_REQUIRED',message:'Invalid email or password'}}));
 await expect(auth[method]('person@example.com','Password1!')).resolves.toMatchObject({success:false,message:'Invalid email or password',error:'AUTH_REQUIRED'});
});
it('shows signup field validation details', async () => {
 fetch.mockResolvedValue(response(422,{error:{message:'Validation failed',details:{password:['Password must contain a number']}}}));
 await expect(auth.signUpWithEmail('person@example.com','password')).resolves.toMatchObject({success:false,message:'Password must contain a number'});
});
it.each(['signInWithEmail', 'signUpWithEmail'])('handles HTML errors in %s and permits retry', async method => {
 fetch.mockResolvedValueOnce({ok:false,status:502,json:async()=>{throw new SyntaxError('HTML');}})
  .mockResolvedValueOnce(response(200,{data:{user:{id:'uuid',email:'person@example.com'}}}));
 expect((await auth[method]('person@example.com','Password1!')).message).toMatch(/try again/i);
 await expect(auth[method]('person@example.com','Password1!')).resolves.toMatchObject({success:true});
});
it.each(['signInWithEmail', 'signUpWithEmail'])('does not authenticate malformed success responses in %s', async method => {
 fetch.mockResolvedValue(response(200,{}));
 await expect(auth[method]('person@example.com','Password1!')).resolves.toMatchObject({success:false});
 expect(auth.currentUser).toBeNull();
});
it('restores device cookies even without a local profile', async () => {
 fetch.mockResolvedValue(response(200,{data:{user:{id:'uuid',email:'person@example.com'}}}));
 const callback=jest.fn();const unsubscribe=auth.onAuthStateChanged(callback);
 await auth._initializationPromise;
 expect(callback).toHaveBeenCalledWith(expect.objectContaining({uid:'uuid'}));
 expect(fetch.mock.calls[0][0]).toMatch(/\/me$/);
 expect(fetch.mock.calls[0][1].credentials).toBe('include');
 expect(auth.getCurrentUser().uid).toBe('uuid');unsubscribe();
});
it('shares startup validation and ignores an unsubscribed listener', async () => {
 let resolve;fetch.mockReturnValue(new Promise(r=>{resolve=r;}));
 const old=jest.fn();auth.onAuthStateChanged(old)();
 const current=jest.fn();const unsubscribe=auth.onAuthStateChanged(current);
 expect(fetch).toHaveBeenCalledTimes(1);
 resolve(response(200,{data:{user:{id:'uuid',email:'person@example.com'}}}));
 await auth._initializationPromise;
 expect(old).not.toHaveBeenCalled();expect(current).toHaveBeenCalledTimes(1);unsubscribe();
});
it('restores a returning user when the access cookie has expired', async () => {
 fetch.mockResolvedValueOnce(response(401,{})).mockResolvedValueOnce(response(200,{data:{}}))
  .mockResolvedValueOnce(response(200,{data:{user:{id:'uuid',email:'person@example.com'}}}));
 await expect(auth.getCurrentUserFromBackend()).resolves.toMatchObject({uid:'uuid'});
 expect(fetch.mock.calls.map(([url])=>url.split('/').pop())).toEqual(['me','refresh','me']);
});
it.each([500,503])('retains the saved user during startup status %s', async status => {
 auth._saveAuth(null,null,{id:'uuid',email:'person@example.com'});fetch.mockResolvedValue(response(status,{}));
 await expect(auth.getCurrentUserFromBackend()).resolves.toMatchObject({uid:'uuid'});
 expect(localStorage.getItem('currentUser')).not.toBeNull();
});
it('retains the saved user when startup is offline', async () => {
 auth._saveAuth(null,null,{id:'uuid'});fetch.mockRejectedValue(new Error('Offline'));
 await expect(auth.getCurrentUserFromBackend()).resolves.toMatchObject({uid:'uuid'});
});
it('ends an expired device session without leaving a stale profile', async () => {
 auth._saveAuth(null,null,{id:'uuid'});fetch.mockResolvedValue(response(401,{}));
 await expect(auth.getCurrentUserFromBackend()).resolves.toBeNull();
 expect(localStorage.getItem('currentUser')).toBeNull();
});
it('does not let slow startup replace a successful new login', async () => {
 let resolve;fetch.mockReturnValueOnce(new Promise(r=>{resolve=r;}));
 const startup=auth.getCurrentUserFromBackend();
 fetch.mockResolvedValueOnce(response(200,{data:{user:{id:'new',email:'new@example.com'}}}));
 await auth.signInWithEmail('new@example.com','Password1!');
 resolve(response(401,{}));await expect(startup).resolves.toMatchObject({uid:'new'});
 expect(auth.currentUser.id).toBe('new');expect(fetch).toHaveBeenCalledTimes(2);
});
it('does not restore a user after signing out during startup', async () => {
 let resolve;fetch.mockReturnValueOnce(new Promise(r=>{resolve=r;}));
 const startup=auth.getCurrentUserFromBackend();
 fetch.mockResolvedValueOnce(response(200,{}));await auth.signOut();
 resolve(response(200,{data:{user:{id:'uuid'}}}));
 await expect(startup).resolves.toBeNull();expect(auth.currentUser).toBeNull();
});
it('uses cookies instead of an old in-memory refresh token', async () => {
 auth.refreshToken='stale-token';fetch.mockResolvedValue(response(200,{data:{}}));
 await auth.refreshAccessToken();expect(fetch.mock.calls[0][1].body).toBe('{}');
});
it('signs in when local storage is unavailable', async () => {
 const storage=jest.spyOn(Storage.prototype,'setItem').mockImplementation(()=>{throw new Error('Storage disabled');});
 fetch.mockResolvedValue(response(200,{data:{user:{id:'uuid',email:'person@example.com'}}}));
 await expect(auth.signInWithEmail('person@example.com','Password1!')).resolves.toMatchObject({success:true});
 expect(auth.getCurrentUser().uid).toBe('uuid');storage.mockRestore();
});
it('times out a stalled login request so the form can be retried', async () => {
 jest.useFakeTimers();
 fetch.mockImplementation((url,{signal})=>new Promise((resolve,reject)=>{
  signal.addEventListener('abort',()=>reject(new Error('Aborted')));
 }));
 const request=auth.signInWithEmail('person@example.com','Password1!');
 jest.advanceTimersByTime(30000);
 await expect(request).resolves.toMatchObject({success:false,message:'Unable to connect. Check your connection and try again.'});
 jest.useRealTimers();
});
it('serializes cookie refreshes across browser tabs and reads the latest CSRF token', async () => {
 let tail=Promise.resolve();
 const request=jest.fn((name,callback)=>{
  const queued=tail.then(callback);tail=queued.catch(()=>{});return queued;
 });
 const previous=navigator.locks;
 Object.defineProperty(navigator,'locks',{configurable:true,value:{request}});
 try {
  const secondTab=new auth.constructor();
  let resolve;
  fetch.mockImplementationOnce(()=>new Promise(r=>{resolve=r;}))
   .mockResolvedValueOnce(response(200,{data:{}}));
  const first=auth.refreshAccessToken();const second=secondTab.refreshAccessToken();
  await Promise.resolve();expect(fetch).toHaveBeenCalledTimes(1);
  document.cookie='csrf_token=rotated; path=/';resolve(response(200,{data:{}}));
  await Promise.all([first,second]);
  expect(request).toHaveBeenCalledTimes(2);
  expect(fetch.mock.calls[1][1]).toMatchObject({body:'{}',headers:{'X-CSRF-Token':'rotated'}});
 } finally { Object.defineProperty(navigator,'locks',{configurable:true,value:previous}); }
});
