---
layout:     post
title:      "微服务安全沉思录之一"
subtitle:   "用户访问认证与鉴权"
description: "这段时间对之前微服务安全相关的一些想法进行了进一步总结和归纳，理清在之前文章里面没有想得太清楚的地方，例如服务间的认证与鉴权以及用户身份在服务调用链中的传递。在这一系列博客里面将分为三个部分对微服务安全进行系统阐述：用户访问认证与鉴权，服务间认证与鉴权，外部系统访问控制。"
excerpt: "这段时间对之前微服务安全相关的一些想法进行了进一步总结和归纳，理清在之前文章里面没有想得太清楚的地方，例如服务间的认证与鉴权以及用户身份在服务调用链中的传递。在这一系列博客里面将分为三个部分对微服务安全进行系统阐述：用户访问认证与鉴权，服务间认证与鉴权，外部系统访问控制。"
date:      2018-05-23T10:00:00
author:     "赵化冰"
image: "/img/2018-05-22-user_authentication_authorization/background.jpg"
publishDate: 2018-05-23T10:00:00
tags:
    - Microservice
    - Security 
URL: "/2018/05/22/user_authentication_authorization"
categories: [ "Tech" ]    
---

> 这段时间对之前微服务安全相关的一些想法进行了进一步总结和归纳，理清了在之前文章里面没有想得太清楚的地方，例如服务间的认证与鉴权以及用户身份在服务调用链中的传递。
> 
> 在这一系列文章里，我将尝试分为三个部分对微服务安全进行系统阐述：用户访问认证与鉴权，服务间认证与鉴权，外部系统访问控制。

## 目录
{:.no_toc}

* 目录
{:toc}


## 前言
微服务架构的引入为软件应用带来了诸多好处：包括小开发团队，缩短开发周期，语言选择灵活性，增强服务伸缩能力等。与此同时，也引入了分布式系统的诸多复杂问题。其中一个挑战就是如何在微服务架构中实现一个灵活，安全，高效的认证和鉴权方案。

相对于传统单体应用，微服务架构下的认证和鉴权涉及到场景更为复杂，涉及到用户访问微服务应用，第三方应用访问微服务应用，应用内多个微服务之间相互访问等多种场景，每种场景下的认证和鉴权方案都需要考虑到，以保证应用程序的安全性。本系列博文将就此问题进行一次比较完整的探讨。
![微服务认证和鉴权涉及到的三种场景](//img/2018-02-03-authentication-and-authorization-of-microservice/auth-scenarios.png)
<center>微服务认证和鉴权涉及到的三种场景</center>

## 用户认证和鉴权

### 用户身份认证
一个完整的微服务应用是由多个相互独立的微服务进程组成的，对每个微服务的访问都需要进行用户认证。如果将用户认证的工作放到每个微服务中，存在下面一些问题：
* 需要在各个微服务中重复实现这部分公共逻辑。虽然我们可以使用代码库复用部分代码，但这又会导致所有微服务对特定代码库及其版本存在依赖，影响微服务语言/框架选择的灵活性。
* 将认证和鉴权的公共逻辑放到微服务实现中违背了单一职责原理，开发人员应重点关注微服务自身的业务逻辑。
* 用户需要分别登录以访问系统中不同的服务。

由于在微服务架构中以API Gateway作为对外提供服务的入口，因此可以在API Gateway处提供统一的用户认证，用户只需要登录一次，就可以访问系统中所有微服务提供的服务。 

### 用户状态保持
HTTP是一个无状态的协议，对服务器来说，用户的每次HTTP请求是相互独立的。互联网是一个巨大的分布式系统，HTTP协议作为互联网上的一个重要协议，在设计之初要考虑到大量应用访问的效率问题。无状态意味着服务端可以把客户端的请求根据需要发送到集群中的任何一个节点，HTTP的无状态设计对负载均衡有明显的好处，由于没有状态，用户请求可以被分发到任意一个服务器，应用也可以在靠近用户的网络边缘部署缓存服务器。对于不需要身份认证的服务，例如浏览新闻网页等，这是没有任何问题的。但HTTP成为企业应用的一个事实标准后，企业应用需要保存用户的登录状态和身份以进行更严格的权限控制。因此需要在HTTP协议基础上采用一种方式保存用户的登录状态，避免用户每发起一次请求都需要进行验证。

传统方式是在服务器端采用Cookie来保存用户状态，由于在服务器是有状态的，对服务器的水平扩展有影响。在微服务架构下建议采用Token来记录用户登录状态。

Token和Seesion主要的不同点是存储的地方不同。Session是集中存储在服务器中的；而Token是用户自己持有的，一般以cookie的形式存储在浏览器中。Token中保存了用户的身份信息，每次请求都会发送给服务器，服务器因此可以判断访问者的身份，并判断其对请求的资源有没有访问权限。

Token用于表明用户身份，因此需要对其内容进行加密，避免被请求方或者第三者篡改。[JWT(Json Web Token)](https://jwt.io)是一个定义Token格式的开放标准(RFC 7519),定义了Token的内容，加密方式，并提供了各种语言的lib。

JWT Token的结构非常简单，包括三部分：
* Header<BR>
头部包含类型,为固定值JWT。然后是JWT使用的Hash算法。
```
{
  "alg": "HS256",
  "typ": "JWT"
}
```
* Payload<BR>
包含发布者，过期时间，用户名等标准信息，也可以添加用户角色，用户自定义的信息。
```
{
  "sub": "1234567890",
  "name": "John Doe",
  "admin": true
}
```
* Signature<BR>
Token颁发方的签名，用于客户端验证Token颁发方的身份，也用于服务器防止Token被篡改。
签名算法
```
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret)
```

这三部分使用Base64编码后组合在一起，成为最终返回给客户端的Token串，每部分之间采用"."分隔。下图是上面例子最终形成的Token
![xx](https://cdn.auth0.com/content/jwt/encoded-jwt3.png)
采用Token进行用户认证，服务器端不再保存用户状态，客户端每次请求时都需要将Token发送到服务器端进行身份验证。Token发送的方式[rfc6750](https://tools.ietf.org/html/rfc6750)进行了规定，采用一个 Authorization: Bearer HHTP Header进行发送。
```
Authorization: Bearer mF_9.B5f-4.1JqM
```
采用Token方式进行用户认证的基本流程如下图所示：
1. 用户输入用户名,密码等验证信息，向服务器发起登录请求
1. 服务器端验证用户登录信息，生成JWT token
1. 服务器端将Token返回给客户端，客户端保存在本地（一般以Cookie的方式保存）
1. 客户端向服务器端发送访问请求，请求中携带之前颁发的Token
1. 服务器端验证Token，确认用户的身份和对资源的访问权限，并进行相应的处理（拒绝或者允许访问）
![](https://cdn.auth0.com/content/jwt/jwt-diagram.png)
<center>采用Token进行用户认证的流程图</center>

### 实现单点登录
单点登录的理念很简单，即用户只需要登录应用一次，就可以访问应用中所有的微服务。API Gateway提供了客户端访问微服务应用的入口，Token实现了无状态的用户认证。结合这两种技术，可以为微服务应用实现一个单点登录方案。

用户的认证流程和采用Token方式认证的基本流程类似，不同之处是加入了API Gateway作为外部请求的入口。

用户登录
1. 客户端发送登录请求到API Gateway
2. API Gateway将登录请求转发到Security Service
3. Security Service验证用户身份，并颁发Token

用户请求
1. 客户端请求发送到API Gateway
1. API Gateway调用的Security Service对请求中的Token进行验证，检查用户的身份
2. 如果请求中没有Token，Token过期或者Token验证非法，则拒绝用户请求。
3. Security Service检查用户是否具有该操作权(可选，参见下一小节)
4. 如果用户具有该操作权限，则把请求发送到后端的Business Service，否则拒绝用户请求
![采用API Gateway实现微服务应用的SSO](/img/2018-05-22-user_authentication_authorization/api-gateway-sso.png)
<center>采用API Gateway和Token实现微服务应用的单点登录</center>

### 用户权限控制
用户权限控制有两种做法，在API Gateway处统一处理，或者在各个微服务中单独处理。
#### API Gateway处进行统一的权限控制
客户端发送的HTTP请求中包含有请求的Resource及HTTP Method。如果系统遵循REST规范，以URI资源方式对访问对象进行建模，则API Gateway可以从请求中直接截取到访问的资源及需要进行的操作，然后调用Security Service进行权限判断，根据判断结果决定用户是否有权限对该资源进行操作，并转发到后端的Business Service。

假设系统中有三个角色:
* order_manager,可以查看，创建，修改，删除订单
* order_editor, 可以查看，创建，修改订单
* order_inspector，只能查看订单

这些角色对资源的操作权限都可以映射到HTTP Verb上，如下表所示。

| Role            | Resource | Verbs                              |
|-----------------|----------|------------------------------------|
| order_manager   | /orders  | 'GET'   'POST'   'PUT'   'DELETE'  |
| order_editor    | /orders  | 'GET'    'POST'    'PUT'           |
| order_inspector | /orders  | 'GET'                              |

这种实现方式在API Gateway处统一处理鉴权逻辑，各个微服务不需要考虑用户鉴权，只需要处理业务逻辑，简化了各微服务的实现。
#### 由各个微服务单独进行权限控制
如果微服务未严格遵循REST规范对访问对象进行建模，或者应用需要进行更细粒度的权限控制，则需要在微服务中单独对用户权限进行判断和处理。这种情况下微服务的权限控制更为灵活，但各个微服务需要单独维护用户的授权数据，实现更复杂。

由于微服务进行权限判断时需要用户身份信息，该方案需要处理的另一个问题是如何把登录用户的信息从API Gateway传递到微服务中。如果是基于Http，可以采用Http header实现，如果是其他协议，则需要在消息体中增加用户身份相关的字段。


