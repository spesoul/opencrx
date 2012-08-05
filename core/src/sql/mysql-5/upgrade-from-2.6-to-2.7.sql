/* This software is published under the BSD license                          */
/* as listed below.                                                          */
/*                                                                           */
/* Copyright (c) 2004-2010, CRIXP Corp., Switzerland                         */
/* All rights reserved.                                                      */
/*                                                                           */
/* Redistribution and use in source and binary forms, with or without        */
/* modification, are permitted provided that the following conditions        */
/* are met:                                                                  */
/*                                                                           */
/* * Redistributions of source code must retain the above copyright          */
/* notice, this list of conditions and the following disclaimer.             */
/*                                                                           */
/* * Redistributions in binary form must reproduce the above copyright       */
/* notice, this list of conditions and the following disclaimer in           */
/* the documentation and/or other materials provided with the                */
/* distribution.                                                             */
/*                                                                           */
/* * Neither the name of CRIXP Corp. nor the names of the contributors       */
/* to openCRX may be used to endorse or promote products derived             */
/* from this software without specific prior written permission              */
/*                                                                           */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND                    */
/* CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,               */
/* INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF                  */
/* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE                  */
/* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS         */
/* BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,                  */
/* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED           */
/* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,             */
/* DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON         */
/* ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,           */
/* OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY            */
/* OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE                   */
/* POSSIBILITY OF SUCH DAMAGE.                                               */
/*                                                                           */
/* ------------------                                                        */
/*                                                                           */
/* This product includes software developed by the Apache Software           */
/* Foundation (http://www.apache.org/).                                      */
/*                                                                           */
/* This product includes software developed by contributors to               */
/* openMDX (http://www.openmdx.org/)                                         */
/*                                                                           */

ALTER TABLE OOCKE1_CALENDARFEED ADD ALLOW_ADD_DELETE BIT;
ALTER TABLE OOCKE1_CALENDARFEED ADD ALLOW_CHANGE BIT;
ALTER TABLE OOCKE1_CALENDARPROFILE ADD DOMAIN VARCHAR(256);
ALTER TABLE OOCKE1_CALENDARPROFILE ADD PASSWORD VARCHAR(256);
ALTER TABLE OOCKE1_CALENDARPROFILE ADD SERVER_URL VARCHAR(256);
ALTER TABLE OOCKE1_CALENDARPROFILE ADD USERNAME VARCHAR(256);
ALTER TABLE OOCKE1_WORKRECORD ADD CATEGORY_ INTEGER DEFAULT -1;
ALTER TABLE OOCKE1_WORKRECORD ADD DISABLED BIT;
ALTER TABLE OOCKE1_WORKRECORD ADD DISABLED_REASON VARCHAR(256);
ALTER TABLE OOCKE1_WORKRECORD ADD EXTERNAL_LINK_ INTEGER DEFAULT -1;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_BOOLEAN0 BIT;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_BOOLEAN1 BIT;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_BOOLEAN2 BIT;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_BOOLEAN3 BIT;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_BOOLEAN4_ INTEGER DEFAULT -1;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_CODE0 SMALLINT;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_CODE1 SMALLINT;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_CODE2 SMALLINT;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_CODE3 SMALLINT;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_CODE4_ INTEGER DEFAULT -1;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_DATE0 DATE;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_DATE1 DATE;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_DATE2 DATE;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_DATE3 DATE;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_DATE4_ INTEGER DEFAULT -1;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_DATE_TIME0 DATETIME;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_DATE_TIME1 DATETIME;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_DATE_TIME2 DATETIME;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_DATE_TIME3 DATETIME;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_DATE_TIME4_ INTEGER DEFAULT -1;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_NUMBER0 NUMERIC;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_NUMBER1 NUMERIC;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_NUMBER2 NUMERIC;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_NUMBER3 NUMERIC;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_NUMBER4_ INTEGER DEFAULT -1;
ALTER TABLE OOCKE1_WORKRECORD ADD USER_STRING0 VARCHAR(256);
ALTER TABLE OOCKE1_WORKRECORD ADD USER_STRING1 VARCHAR(256);
ALTER TABLE OOCKE1_WORKRECORD ADD USER_STRING2 VARCHAR(256);
ALTER TABLE OOCKE1_WORKRECORD ADD USER_STRING3 VARCHAR(256);
ALTER TABLE OOCKE1_WORKRECORD ADD USER_STRING4_ INTEGER DEFAULT -1;
ALTER TABLE OOCKE1_WORKRECORD_ ADD CATEGORY VARCHAR(256);
ALTER TABLE OOCKE1_WORKRECORD_ ADD EXTERNAL_LINK VARCHAR(256);
ALTER TABLE OOCKE1_WORKRECORD_ ADD USER_BOOLEAN4 BIT;
ALTER TABLE OOCKE1_WORKRECORD_ ADD USER_CODE4 SMALLINT;
ALTER TABLE OOCKE1_WORKRECORD_ ADD USER_DATE4 DATE;
ALTER TABLE OOCKE1_WORKRECORD_ ADD USER_DATE_TIME4 DATETIME;
ALTER TABLE OOCKE1_WORKRECORD_ ADD USER_NUMBER4 NUMERIC;
ALTER TABLE OOCKE1_WORKRECORD_ ADD USER_STRING4 VARCHAR(256);