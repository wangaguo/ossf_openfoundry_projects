��    &      L  5   |      P  -  Q       /   �  /   �  4   �  �   #     �     �  x   �  �   ;  c     �   g  �   \     �  )   	  Y   9	  �   �	  
   
     $
     +
  ;   K
  >   �
  �   �
  <   �     �  0       7  �   ?  �     �   �  t   %  D   �  F   �  �   &  u   �  �   @  ,   0    ]  �   c     M  6   a  6   �  2   �  |             �  ^   �  �   �  g   �  �   �     �     �  3   �  X        w  	   �     �  )   �  U   �  D   "     g     �     �     �     �     �     �                9  K   R     �     �     �  #   �                           &                                
       	              %                              $                    "   !                                      #       <em>modelist</em> is a list of modes (mail, notice, digest, digestplain, summary, nomail), separated by commas. Only these modes will be allowed for the subscribers of this list. If a subscriber has a reception mode not in the list, sympa uses the mode specified in the default_user_options paragraph. Default value: Default value: bounce_halt_rate robot parameter Default value: bounce_warn_rate robot parameter Defines who can access the web archive for the list. Deletion message : This message is sent to users when you
remove them from the list using the DEL command (unless you hit the
Quiet button. Digest DigestPlain Domain name of the list, default is the robot domain name set in the related robot.conf file or in file /etc/sympa.conf. Editors are responsible for moderating messages. If the mailing list is moderated, messages posted to the list will first be passed to the editors, who will decide whether to distribute or reject it. FYI: Defining editors will not make the list moderated ; you will have to set the "send" parameter. FYI: If the list is moderated, any editor can distribute or reject a message without the knowledge or consent of the other editors. Messages that have not been distributed or rejected will remain in the moderation spool until they are acted on. List owners may decide to add message headers or footers to messages sent via the list. This parameter defines the way a footer/header is added to a message. Mail reception mode. Maximum size of a message in 8-bit bytes. Message footer : same as <em>Message header,</em> but attached at the
end of the message. Message header: If this file is not empty, it is added as a MIME
attachment at the beginning of each message distributed to the list. No Comment Nomail Other files/pages description : Privilege for adding (ADD command) a subscriber to the list Privilege for reading mail archives and frequency of archiving Remind message : This message is sent to each subscriber
when using the command  REMIND. It's very useful to help people who are
confused about their own subscription emails or people who are not able to
unsubscribe themselves. Same as welcome_return_path, but applied to remind messages. Service messages description : Similar to the Digest option in that the subscriber will periodically 
receive batched messages in a Digest. With DigestPlain the Digest is sent in a plain text 
format, with all attachments stripped out. DigestPlain is useful if your email software doesn't
display multipart/digest format messages well. Summary Sympa will not create new MIME parts, but will try to append the header/footer to the body of the message. Predefined message-footers will be ignored. Headers/footers may be appended to text/plain messages only. The Bouncers_level1 paragraphs defines the automatic behavior of bounce management.<br />
	Level 1 is the lower level of bouncing users The Bouncers_levelX paragraphs defines the automatic behavior of bounce management.<br />
	Level 2 is the highest level of bouncing users The available_user_options parameter starts a paragraph to define available options for the subscribers of the list. The sending interval for these Digests is defined by the list owner. The subscribe parameter defines the rules for subscribing to the list. This mode is used when a subscriber does not want to receive attached files. The attached files are 
replaced by a URL leading to the file stored on the list site. This mode is used when a subscriber does not want to receive copies of messages that he or she has sent to 
the list. This mode is used when a subscriber no longer wishes to receive mail from the list, but nevertheless wishes to retain the ability to post to the list. This mode therefore prevents the subscriber from unsubscribing and subscribing later on. the @ char is replaced by the string " AT ". Project-Id-Version: sympa
Report-Msgid-Bugs-To: FULL NAME <EMAIL@ADDRESS>
POT-Creation-Date: 2007-11-13 14:50+0200
PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE
Last-Translator: FULL NAME <EMAIL@ADDRESS>
Language-Team: Turkish <tr@li.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
#-#-#-#-#  blank_web_help_tr.po (sympa)  #-#-#-#-#
Plural-Forms: nplurals=1; plural=0;
#-#-#-#-#  tmp_web_help_tr.po (sympa)  #-#-#-#-#
X-Rosetta-Version: 0.1
Plural-Forms: nplurals=1; plural=0
 <em>modelist</em> modların bir listesidir. (mail, notice, digest, digestplain, summary, nomail). Sadece bu modların kullanımına izin verilir. Eğer bir kullanıcı listede olmayan bir mod seçerse sympa varsayılan modu kullanır Varsayılan değer: Varsayılan değer: bounce_halt_rate robot parametresi Varsayılan değer: bounce_warn_rate robot parametresi Kimlerin web arşivine ulaşabileceğini tanımlar Silme mesajı: Bu mesaj listenizden DEL komutu ile sildiğiniz kullanıcılara gönderilir. (quite butonuna basmadıysanız) Özet DigestPlain Liste alan adı, varsayılan değer robot.conf veya /etc/sympa.conf dosyasında tanımlıdır. Editörler mesajları onaylamakla yükümlüdür. Eğer bir liste onaylı ise gelen mesajlar editörlere yönlendirilir. editörler mesajı onaylar ya da reddeder. Bilgi: Editör tanımlamak listeyi onaylı hale getirmez. Gönderim seçeneklerini değiştirmelisiniz. Bilgi: Eğer liste onaylı olursa, bir editör diğer editörlerden bağımsız olarak bir mesajı onaylayabilir ya da reddebilir. İşlenmeyen mesajlar işlenene kadar mesaj havuzunda beklerler.                          Mail kabul modu. Mesajın 8.bit'lik byte olarak azami büyüklüğü Mesaj altlığı: <em>Mesaj başlığı</em> ile aynı, fakat
mesajın sonuna eklenmiş.                          Yorum Yok Mailyok Diğer dosyaların/sayfaların tanımı : Belirlenmiş bir listeye kayıtlı kullanıcı eklemek için (ADD komutu) ayrıcalık Mail arşivlerini okumak ve arşivleme sıklığı için ayrıcalık                                                   Servis mesajları tanımı :                          Özet                                                                                                                              Kayıt parametresi, listeye kayıtlanma için gereken kuralları tanımlar.                                                                            @ karakteri "AT" ile değiştirildi 