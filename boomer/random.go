package boomer 

import (
   "crypto/md5"
   "encoding/hex"
   "math/rand"
   "time"
)

// MD5 generates 32 MD5 value
func MD5(text string) string {
   ctx := md5.New()
   ctx.Write([]byte(text))
   return hex.EncodeToString(ctx.Sum(nil))
}

// GetRandomSalt returns random salt
func GetRandomSalt() string {
   return GetRandomString(8)
}

//GetRandomString generates random string
func GetRandomString(length int64) string {
   str := "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
   bytes := []byte(str)
   result := []byte{}
   r := rand.New(rand.NewSource(time.Now().UnixNano()))
   
   for i := int64(0); i < length; i++ {
      result = append(result, bytes[r.Intn(len(bytes))])
   }
   return string(result)
}